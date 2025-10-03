% Write two chunks
meta1 = writeFloatArrayChunk('clients_data.bin', rand(1,5));
meta2 = writeFloatArrayChunk('clients_data.bin', [1 2 3 4 5]);

% Read back the first chunk
[data1, m1] = readFloatArrayChunk('clients_data.bin', 1);
disp(m1)
disp(data1)
