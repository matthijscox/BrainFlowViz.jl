using BrainFlow
using BrainFlowViz

function get_some_board_data(board_shim, nsamples)
    data = BrainFlow.get_current_board_data(nsamples, board_shim)
    eeg_chans = BrainFlow.get_eeg_channels(board_shim.board_id)
    data = transpose(data)
    return view(data, :, eeg_chans)
end

function calc_avg_band_powers(data, board_id = BrainFlow.SYNTHETIC_BOARD)
    chans = 1:size(data, 2)
    sampling_rate = BrainFlow.get_sampling_rate(board_id)
    apply_filter = true
    avg_band_power = BrainFlow.get_avg_band_powers(transpose(data), chans, sampling_rate, apply_filter)
end

### Start streaming
BrainFlow.enable_dev_logger(BrainFlow.BOARD_CONTROLLER)
params = BrainFlowInputParams()
board_shim = BrainFlow.BoardShim(BrainFlow.SYNTHETIC_BOARD, params)
BrainFlow.prepare_session(board_shim)
BrainFlow.start_stream(board_shim)

nchannels = length(BrainFlow.get_eeg_channels(board_shim.board_id))
nsamples = 256

# brief sleep
sleep(0.5)

data_func = ()->get_some_board_data(board_shim, nsamples)

# start a live plotting task
BrainFlowViz.plot_data(
    data_func, 
    nsamples, 
    nchannels, 
    theme = :dark, 
    color = :lime,
    delay = 0.02,
    ncolumns = 2,
    column_gap = 500,
    layout_size = (1500, 700)
    )

# this should go into a 'finally' of try/catch/finally
# BrainFlow.stop_stream(board_shim)
# BrainFlow.release_session(board_shim)