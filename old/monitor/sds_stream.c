// visa_panel.c — NI-VISA test panel for Siglent SDS1104X-U (and siblings)
// Robust ASCII/binary reads, CHDR quirks handled, script + interactive modes.
// Adds helpful directives: :sleep, :timeout, :wait_sast, :acq_once, :fetch4.
//
// One-shot recipe (per Siglent programming guide):
//   ARM  -> wait Ready -> FRTR (force one acquisition) -> wait Stop  (then fetch)
//   (FRTR = FORCE_TRIGGER; SAST? = acquisition status.)  Docs list ARM/FRTR/SAST. [1][2]
//
// [1] Table lists ARM and FRTR (FORCE_TRIGGER).  [2] SAST? “acquisition status”.
//   (Siglent “Digital Oscilloscopes Series – Programming Guide”)
//   Citations: turn3view1 (ARM/FRTR table), turn1view0 (SAST page)

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <ctype.h>
#include <stdarg.h>
#include <math.h>
#include <signal.h>
#include <time.h>
#include <errno.h>
#include <visa.h>

#ifndef VI_ERROR_TMO
#define VI_ERROR_TMO 0xBFFF0015
#endif

#define IO_TIMEOUT_DEFAULT 1000
#define MAX_LINE           4096
#define BIN_PREVIEW        64

static volatile sig_atomic_t g_stop = 0;
static void on_sigint(int sig){ (void)sig; g_stop = 1; }

/* ---------- time + logging ---------- */

static double now_s(void){
#if defined(CLOCK_MONOTONIC)
    struct timespec ts; clock_gettime(CLOCK_MONOTONIC, &ts);
#else
    struct timespec ts; clock_gettime(CLOCK_REALTIME, &ts);
#endif
    return ts.tv_sec + ts.tv_nsec/1e9;
}

static void ts_now(char out[24]){
    double t = now_s();
    time_t wall = time(NULL);
    struct tm *lt = localtime(&wall);
    int ms = (int)floor((t - floor(t))*1000.0);
    strftime(out, 24, "%H:%M:%S", lt);
    sprintf(out+8, ".%03d", ms);
}

static void msleep(int ms){
    struct timespec ts; ts.tv_sec = ms/1000; ts.tv_nsec = (ms%1000)*1000000L;
    nanosleep(&ts, NULL);
}

static void rstrip(char* s){
    size_t L=strlen(s);
    while (L && (s[L-1]=='\n'||s[L-1]=='\r'||s[L-1]==' '||s[L-1]=='\t')) s[--L]=0;
}

static const char* status_desc(ViSession any, ViStatus st, char* buf, size_t bufsz){
    ViChar desc[256]={0};
    ViStatus s = viStatusDesc(any ? any : VI_NULL, st, desc);
    if (s >= VI_SUCCESS && desc[0]) snprintf(buf, bufsz, "%s", (const char*)desc);
    else snprintf(buf, bufsz, "");
    return buf;
}

static void log_line(FILE* fp, const char* prefix, const char* msg){
    char ts[24]; ts_now(ts);
    fprintf(fp ? fp : stderr, "[%s] %s%s\n", ts, prefix, msg);
    if (fp) fflush(fp);
}

static void log_resp_ascii(FILE* fp, ViSession ses, ViStatus st, const char* data){
    char ts[24]; ts_now(ts);
    char sd[256]; status_desc(ses, st, sd, sizeof(sd));
    fprintf(fp ? fp : stderr, "[%s] << (st=0x%08X,desc='%s') \"%s\"\n",
            ts, (unsigned)st, sd, data ? data : "");
    if (fp) fflush(fp);
}

static void log_resp_binary(FILE* fp, ViSession ses, ViStatus st, int full_len,
                            const uint8_t* buf, int blen){
    char ts[24]; ts_now(ts);
    char sd[256]; status_desc(ses, st, sd, sizeof(sd));
    fprintf(fp ? fp : stderr, "[%s] << (st=0x%08X,desc='%s') BINARY len=%d preview=",
            ts, (unsigned)st, sd, full_len);
    int n = (blen < BIN_PREVIEW ? blen : BIN_PREVIEW);
    for (int i=0;i<n;i++) fprintf(fp ? fp : stderr, "%02X%s", buf[i], (i+1==n)?"":" ");
    fprintf(fp ? fp : stderr, "%s\n", blen>n ? " ..." : "");
    if (fp) fflush(fp);
}

/* ---------- VISA helpers ---------- */

static ViStatus scpi_write(ViSession s, const char* line){
    ViUInt32 n=0; size_t L=strlen(line);
    char buf[MAX_LINE+2];
    if (L+1 > MAX_LINE) return VI_ERROR_TMO;
    memcpy(buf, line, L); buf[L]='\n'; buf[L+1]=0;
    viFlush(s, VI_READ_BUF_DISCARD);               // drop any stale input
    return viWrite(s, (ViBuf)buf, (ViUInt32)(L+1), &n);
}

static int is_query(const char* s){ return strchr(s, '?') != NULL; }

/* Read until newline OR short timeout; returns malloc'd string (caller frees). */
static char* read_ascii_line_or_all(ViSession s, ViStatus* out_st){
    size_t cap=1024, used=0;
    char* out = (char*)malloc(cap);
    if (!out){ if(out_st)*out_st=VI_ERROR_TMO; return NULL; }

    for(;;){
        ViUInt32 got=0; unsigned char b=0;
        ViStatus st = viRead(s, (ViBuf)&b, 1, &got);
        if (st < VI_SUCCESS){
            if (st == VI_ERROR_TMO){ *out_st = VI_SUCCESS; break; }   // end
            *out_st = st; break;
        }
        if (got == 1){
            if (used+1 >= cap){ cap*=2; char* t=(char*)realloc(out,cap); if(!t){ free(out); if(out_st)*out_st=VI_ERROR_TMO; return NULL; } out=t; }
            out[used++] = (char)b;
            if (b == '\n') { *out_st = VI_SUCCESS; break; }
        }
    }
    out[used]=0; rstrip(out);
    return out;
}

/* Read binary payload (up to maxcpy) after we already parsed the #N<len> header */
static int read_binary_payload(ViSession s, uint8_t* dst, int decl, int maxcpy, ViStatus* pst){
    int want = decl < maxcpy ? decl : maxcpy;
    int got = 0;
    while (got < want){
        ViUInt32 chunk=0;
        ViStatus st = viRead(s, (ViBuf)(dst+got), (ViUInt32)(want-got), &chunk);
        if (st < VI_SUCCESS){
            if (st == VI_ERROR_TMO){ *pst = VI_SUCCESS; break; }
            *pst = st; return -1;
        }
        got += (int)chunk;
        if (chunk == 0) break;
    }
    *pst = VI_SUCCESS;
    return got;
}

/* Send command, then read/log response (ASCII or binary with optional preamble) */
static ViStatus send_and_report(ViSession inst, const char* line, FILE* logfp){
    /* log outgoing */
    char cmdbuf[MAX_LINE+32];
    snprintf(cmdbuf, sizeof(cmdbuf), ">> %s", line);
    log_line(logfp, "", cmdbuf);

    /* write */
    ViStatus stw = scpi_write(inst, line);
    if (stw < VI_SUCCESS){ log_resp_ascii(logfp, inst, stw, ""); return stw; }

    /* non-queries get no reply (usually) */
    if (!is_query(line)){
        log_resp_ascii(logfp, inst, stw, "OK (no response expected)");
        return stw;
    }

    /* query: read stream; scan to first '#'; else collect ASCII line */
    char pre[1024]; int pre_used=0;
    for (;;){
        ViUInt32 got=0; unsigned char b=0;
        ViStatus p = viRead(inst, (ViBuf)&b, 1, &got);
        printf("got %d: ",got);
        if(got>2) for(int i=0;i<got;i++) printf("%hhx(%c) ",b[i],b[i]);
        printf("\n");
        if (p < VI_SUCCESS){
            if (p == VI_ERROR_TMO){
                pre[pre_used]=0; rstrip(pre);
                log_resp_ascii(logfp, inst, VI_SUCCESS, pre);
                return VI_SUCCESS;
            } else {
                pre[pre_used]=0; rstrip(pre);
                log_resp_ascii(logfp, inst, p, pre);
                return p;
            }
        }
        if (got != 1) continue;

        if (b == '#'){
            /* parse #<N><len> */
            ViUInt32 n=0; char d=0;
            p = viRead(inst, (ViBuf)&d, 1, &n);
            if (p < VI_SUCCESS || n!=1 || d<'0'||d>'9'){ log_resp_ascii(logfp, inst, p, "<binary header error>"); return p; }
            int nd = d - '0';
            char lenbuf[16]={0};
            p = viRead(inst, (ViBuf)lenbuf, (ViUInt32)nd, &n);
            if (p < VI_SUCCESS || (int)n != nd){ log_resp_ascii(logfp, inst, p, "<binary length error>"); return p; }
            int decl = (int)strtol(lenbuf, NULL, 10);

            uint8_t buf[BIN_PREVIEW];
            ViStatus rp = VI_SUCCESS;
            int copied = read_binary_payload(inst, buf, decl, (int)sizeof(buf), &rp);

            if (pre_used){ pre[pre_used]=0; rstrip(pre); log_resp_ascii(logfp, inst, VI_SUCCESS, pre); }
            log_resp_binary(logfp, inst, rp, decl, buf, copied);
            return rp;
        } else {
            /* ASCII char; accumulate; stop at newline if no block arrived */
            if (pre_used < (int)sizeof(pre)-1) pre[pre_used++] = (char)b;
            if (b == '\n'){
                pre[pre_used]=0; rstrip(pre);
                log_resp_ascii(logfp, inst, VI_SUCCESS, pre);
                return VI_SUCCESS;
            }
        }
    }
}

/* ---------- script + interactive ---------- */

static void strip_inline_comment(char* line){
    for (char* p=line; *p; ++p){
        if (*p == '#'){ *p = '\0'; rstrip(line); return; }
    }
}

/* helpers for directives */
static int query_sast(ViSession inst, char* out, size_t outsz){
    ViUInt32 n=0; ViStatus st;
    st = scpi_write(inst, "SAST?");
    if (st < VI_SUCCESS){ out[0]=0; return (int)st; }

    size_t used=0;
    for(;;){
        unsigned char b=0; n=0;
        st = viRead(inst, &b, 1, &n);
        if (st < VI_SUCCESS){
            if (st == VI_ERROR_TMO) break;
            out[0]=0; return (int)st;
        }
        if (n==1){
            if (used+1 < outsz) out[used++] = (char)b;
            if (b=='\n') break;
        }
    }
    out[used]=0; rstrip(out);
    return VI_SUCCESS;
}

static int wait_sast_contains(ViSession inst, const char* token, int ms_total, FILE* logfp){
    double t0 = now_s();
    char buf[128];
    while ((now_s()-t0)*1000.0 < ms_total && !g_stop){
        int st = query_sast(inst, buf, sizeof(buf));
        char line[MAX_LINE]; snprintf(line, sizeof(line), "poll SAST? -> \"%s\"", (st>=0)?buf:"<err>");
        log_line(logfp, "", line);
        if (st >= 0 && strstr(buf, token)) return 1;
        msleep(100);
    }
    return 0;
}

static void do_fetch4(ViSession inst, FILE* logfp){
    const char* chans[4] = {"C1","C2","C3","C4"};
    for (int i=0;i<4;i++){
        char cmd[32]; snprintf(cmd,sizeof(cmd),"WAV:SOUR %s",chans[i]);
        send_and_report(inst, cmd, logfp);
        send_and_report(inst, "WAV:DATA?", logfp);
    }
}

static void run_script(ViSession inst, const char* runpath, FILE* logfp, int* timeout_ms){
    FILE* fp = fopen(runpath, "r");
    if (!fp){ fprintf(stderr,"Cannot open script '%s': %s\n", runpath, strerror(errno)); return; }

    char line[MAX_LINE];
    while (!g_stop && fgets(line, sizeof(line), fp)){
        rstrip(line);
        if (!line[0]) continue;
        if (!strncmp(line,"<<",2)) continue;
        if (line[0]=='#') continue;
        if (!strncmp(line,">>",2)){ const char* p=line+2; while(*p==' ')++p; memmove(line,p,strlen(p)+1); }
        strip_inline_comment(line);
        if (!line[0]) continue;

        if (line[0]==':' && isupper((unsigned char)line[1])){
            send_and_report(inst, line, logfp);
            continue;
        }
        if (line[0]==':'){
            if (!strncasecmp(line,":sleep",6)){ int ms=atoi(line+6); if(ms>0) msleep(ms); continue; }
            if (!strncasecmp(line,":timeout",8)){ int ms=atoi(line+8); if(ms>0){ *timeout_ms=ms; viSetAttribute(inst, VI_ATTR_TMO_VALUE, *timeout_ms);} continue; }
            if (!strncasecmp(line,":wait_sast",10)){
                char tok[16]="S"; int ms=3000;
                sscanf(line+10, "%15s %d", tok, &ms);
                int ok = wait_sast_contains(inst, tok, ms, logfp);
                char msg[128]; snprintf(msg,sizeof(msg), "wait_sast \"%s\" %s", tok, ok?"OK":"TIMEOUT");
                log_line(logfp, "", msg);
                continue;
            }
            if (!strncasecmp(line,":acq_once",9)){
                int ms_ready=3000, ms_stop=3000;
                sscanf(line+9, "%d %d", &ms_ready, &ms_stop);
                send_and_report(inst, "ARM", logfp);            // enter Single [table lists ARM]
                wait_sast_contains(inst, "Ry", ms_ready, logfp); // wait Ready
                send_and_report(inst, "FRTR", logfp);           // force acquisition [table lists FRTR]
                wait_sast_contains(inst, "S", ms_stop, logfp);  // wait Stop
                continue;
            }
            if (!strncasecmp(line,":fetch4",7)){ do_fetch4(inst, logfp); continue; }
            if (!strncasecmp(line,":quit",5) || !strncasecmp(line,":exit",5)) break;
            if (!strncasecmp(line,":help",5)){
                log_line(logfp,"", "Directives: :sleep <ms> | :timeout <ms> | :wait_sast <token> <ms> | :acq_once [ms_ready ms_stop] | :fetch4");
                continue;
            }
            // fall through: unknown ":" -> treat as SCPI
        }

        send_and_report(inst, line, logfp);
    }
    fclose(fp);
}

int main(int argc, char** argv){
    setvbuf(stdout,NULL,_IONBF,0);
    setvbuf(stderr,NULL,_IONBF,0);
    signal(SIGINT, on_sigint);

    const char* resource_default = "USB0::0xF4EC::0x1012::SDSAHBAX6R0452::INSTR";
    const char* resource = resource_default;
    const char* logpath  = NULL;
    const char* runpath  = NULL;
    int timeout_ms = IO_TIMEOUT_DEFAULT;

    if (argc >= 2 && argv[1][0] != '-') resource = argv[1];
    if (argc >= 3 && argv[2][0] != '-') runpath  = argv[2];

    for (int i=1;i<argc;i++){
        if (!strcmp(argv[i],"--resource") && i+1<argc) resource = argv[++i];
        else if (!strcmp(argv[i],"--log") && i+1<argc) logpath = argv[++i];
        else if (!strcmp(argv[i],"--run") && i+1<argc) runpath = argv[++i];
        else if (!strcmp(argv[i],"--timeout") && i+1<argc) timeout_ms = atoi(argv[++i]);
        else if (!strcmp(argv[i],"--help")){
            printf("Usage:\n  %s [resource] [cmdfile]\n  %s --resource VISA --run file --log log --timeout ms\n", argv[0], argv[0]);
            return 0;
        }
    }

    FILE* logfp = NULL;
    if (logpath){
        logfp = fopen(logpath, "a");
        if (!logfp){ fprintf(stderr,"Cannot open log '%s': %s\n", logpath, strerror(errno)); }
    }

    ViSession rm = VI_NULL, inst = VI_NULL;
    ViStatus st = viOpenDefaultRM(&rm);
    if (st < VI_SUCCESS){ fprintf(stderr,"viOpenDefaultRM failed: 0x%X\n",(unsigned)st); return 1; }

    st = viOpen(rm, resource, VI_NULL, VI_NULL, &inst);
    if (st < VI_SUCCESS){
        char sd[256]; status_desc(rm, st, sd, sizeof(sd));
        fprintf(stderr,"viOpen('%s') failed: 0x%X %s\n", resource, (unsigned)st, sd);
        viClose(rm); return 2;
    }

    viSetAttribute(inst, VI_ATTR_TMO_VALUE, timeout_ms);
    viSetAttribute(inst, VI_ATTR_TERMCHAR_EN, VI_FALSE);
    viSetAttribute(inst, VI_ATTR_SUPPRESS_END_EN, VI_TRUE);

    char banner[256];
    snprintf(banner, sizeof(banner), "Connected to %s  (timeout=%d ms)", resource, timeout_ms);
    log_line(logfp, "", banner);

    if (runpath) run_script(inst, runpath, logfp, &timeout_ms);
    else {

    printf("NI-VISA test panel — queries are any line containing '?'. Directives:\n");
    printf("  :sleep <ms> | :timeout <ms> | :wait_sast <A|Ry|S> <ms> | :acq_once [ms_ready ms_stop] | :fetch4\n");
    char last[MAX_LINE]={0};
    for (;;){
        if (g_stop) break;
        printf("visa> ");
        char line[MAX_LINE];
        if (!fgets(line, sizeof(line), stdin)) break;
        rstrip(line);
        if (!line[0]){ if (last[0]) strcpy(line,last); else continue; }
        strip_inline_comment(line);
        if (!line[0]) continue;

        if (!strcmp(line,":quit") || !strcmp(line,":exit")) break;
        if (!strncasecmp(line,":sleep",6)){ int ms=atoi(line+6); if(ms>0) msleep(ms); continue; }
        if (!strncasecmp(line,":timeout",8)){ int ms=atoi(line+8); if(ms>0){ timeout_ms=ms; viSetAttribute(inst, VI_ATTR_TMO_VALUE, timeout_ms);} continue; }
        if (!strncasecmp(line,":wait_sast",10)){
            char tok[16]="S"; int ms=3000; sscanf(line+10, "%15s %d", tok, &ms);
            int ok = wait_sast_contains(inst, tok, ms, logfp);
            char msg[128]; snprintf(msg,sizeof(msg), "wait_sast \"%s\" %s", tok, ok?"OK":"TIMEOUT");
            log_line(logfp, "", msg); continue;
        }
        if (!strncasecmp(line,":acq_once",9)){
            int ms_ready=3000, ms_stop=3000; sscanf(line+9, "%d %d", &ms_ready, &ms_stop);
            send_and_report(inst, "ARM", logfp);
            wait_sast_contains(inst, "Ry", ms_ready, logfp);
            send_and_report(inst, "FRTR", logfp);
            wait_sast_contains(inst, "S", ms_stop, logfp);
            continue;
        }
        if (!strncasecmp(line,":fetch4",7)){ do_fetch4(inst, logfp); continue; }

        if (line[0]==':' && isupper((unsigned char)line[1])){
            strcpy(last, line);
            send_and_report(inst, line, logfp);
            continue;
        }

        strcpy(last, line);
        send_and_report(inst, line, logfp);
    }
    }

    if (logfp) fclose(logfp);
    viClose(inst);
    viClose(rm);
    return g_stop ? 130 : 0;
}
