using BrainFlow
using BrainFlowViz

function get_some_board_data(board_shim, nsamples, nchannels=4)
    data = BrainFlow.get_current_board_data(nsamples, board_shim)
    data = transpose(data)
    eeg_chans = BrainFlow.get_eeg_channels(board_shim.board_id)
    emg_data = view(data, :, eeg_chans)
    for chan in 1:nchannels
        emg_channel_data = view(emg_data, :, chan)
        BrainFlow.detrend(emg_channel_data, BrainFlow.CONSTANT)
    end
    return emg_data
end

### Start streaming
BrainFlow.enable_dev_logger(BrainFlow.BOARD_CONTROLLER)
params = BrainFlowInputParams(serial_port="COM5")
board_shim = BrainFlow.BoardShim(BrainFlow.MUSE_2_BLED_BOARD, params)
BrainFlow.prepare_session(board_shim)
BrainFlow.start_stream(board_shim)

nchannels = length(BrainFlow.get_eeg_channels(board_shim.board_id))
nsamples = 512
data_func = ()->get_some_board_data(board_shim, nsamples, nchannels)

# start a live plotting task
BrainFlowViz.plot_data(
    data_func, 
    nsamples, 
    nchannels; 
    #y_lim = [-200 200], 
    theme = :dark,
    color = :lime,
    )

# this should go into a 'finally' of try/catch/finally
"""
BrainFlow.stop_stream(board_shim)
BrainFlow.release_session(board_shim)
"""