using BrainFlow
using BrainFlowViz

function filter_bandstop!(
    data::AbstractVector, 
    board_shim::BrainFlow.BoardShim;
    filter_type::BrainFlow.FilterType = BrainFlow.Butterworth(),
    center_freq::Float64 = 50.0,
    band_width::Float64 = 4.0, 
    order::Integer = 4, 
    ripple::Float64 = 1.0
)
    sampling_rate = BrainFlow.get_sampling_rate(board_shim.board_id)
    BrainFlow.perform_bandstop(data, sampling_rate, center_freq,
    band_width, order, filter_type, ripple)
end

function get_some_board_data(board_shim, nsamples)
    data = BrainFlow.get_current_board_data(nsamples, board_shim)
    eeg_chans = BrainFlow.get_eeg_channels(board_shim.board_id)
    data = transpose(data)
    eeg_data = view(data, :, eeg_chans)
    for chan in 1:length(eeg_chans)
        channel_data = view(eeg_data, :, chan)
        filter_bandstop!(channel_data, board_shim)
        BrainFlow.detrend(channel_data, BrainFlow.CONSTANT)
    end
    return eeg_data
end

### Start streaming
BrainFlow.enable_dev_logger(BrainFlow.BOARD_CONTROLLER)
params = BrainFlowInputParams(serial_port="COM5")
board_shim = BrainFlow.BoardShim(BrainFlow.CYTON_DAISY_BOARD, params)
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
    column_gap = 680,
    layout_size = (1800, 900),
    board_id = board_shim.board_id
    )

# this should go into a 'finally' of try/catch/finally
# BrainFlow.stop_stream(board_shim)
# BrainFlow.release_session(board_shim)