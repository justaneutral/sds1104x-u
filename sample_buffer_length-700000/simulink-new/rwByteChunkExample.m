% Write two byte chunks
meta1 = writeByteChunk('byte_log.bin', uint8([1 2 3 4 5]));
meta2 = writeByteChunk('byte_log.bin', uint8('Привет')); % UTF-8 bytes example

% Read back the second chunk
[b2, m2] = readByteChunk('byte_log.bin', 2);
disp(m2)
disp(b2)             % uint8 row
char(b2)             % if you know these are ASCII/UTF-8 text
