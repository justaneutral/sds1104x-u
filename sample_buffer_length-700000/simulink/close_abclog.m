function close_abclog(fid)
% CLOSE_ABCLOG Close a previously opened file id.
    validateattributes(fid, {'numeric'}, {'scalar','integer','nonnegative'});
    st = fclose(fid);
    if st ~= 0
        error('close_abclog:closeFailed', 'Failed to close file (fid=%d).', fid);
    end
end
