using BrainFlow
using BrainFlowViz

function get_some_board_data(board_shim, nsamples)
    data = BrainFlow.get_current_board_data(nsamples, board_shim)
    data = transpose(data)
    emg_data = view(data, :, 2:9)
    for chan in 1:8
        emg_channel_data = view(emg_data, :, chan)
        BrainFlow.detrend(emg_channel_data, BrainFlow.CONSTANT)
    end
    return emg_data
end

### Start streaming
BrainFlow.enable_dev_logger(BrainFlow.BOARD_CONTROLLER)
params = BrainFlowInputParams()
board_shim = BrainFlow.BoardShim(BrainFlow.GFORCE_PRO_BOARD, params)
BrainFlow.prepare_session(board_shim)
BrainFlow.start_stream(board_shim)

nchannels = 8
nsamples = 512
data_func = ()->get_some_board_data(board_shim, nsamples)

# start a live plotting task
t = @task BrainFlowViz.plot_data(
    data_func, 
    nsamples, 
    nchannels; 
    y_lim = [-1300 1300], 
    theme = :dark,
    color = :lime,
    )

sleep(0.5)
schedule(t)

sleep(4)

### to stop the task:
schedule(t, InterruptException(), error=true)

# this should go into a 'finally' of try/catch/finally
BrainFlow.stop_stream(board_shim)
BrainFlow.release_session(board_shim)