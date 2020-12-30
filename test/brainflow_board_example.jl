using BrainFlow
using BrainFlowViz

function get_some_board_data(board_shim, nsamples)
    data = BrainFlow.get_current_board_data(nsamples, board_shim)
    data = transpose(data)
    return view(data, :, 2:9)
end

nchannels = 8
nsamples = 256

### Start streaming
BrainFlow.enable_dev_logger(BrainFlow.BOARD_CONTROLLER)
params = BrainFlowInputParams()
board_shim = BrainFlow.BoardShim(BrainFlow.SYNTHETIC_BOARD, params)
BrainFlow.prepare_session(board_shim)
BrainFlow.start_stream(board_shim)

# brief sleep
sleep(1)

data_func = ()->get_some_board_data(board_shim, nsamples)

# start a live plotting task
t = @task BrainFlowViz.plot_data(data_func, nsamples, nchannels)
schedule(t)

sleep(4)

### to stop the task:
schedule(t, InterruptException(), error=true)

# this should go into a 'finally' of try/catch/finally
BrainFlow.stop_stream(board_shim)
BrainFlow.release_session(board_shim)