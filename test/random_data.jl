using BrainFlow
using BrainFlowViz

nchannels = 8
nsamples = 256

# start a live plotting task
data_func = ()->rand(nsamples, nchannels)
t = @task BrainFlowViz.plot_data(data_func, nsamples, nchannels; y_lim = (0, 1))
schedule(t)

sleep(5)

### to stop the task:
schedule(t, InterruptException(), error=true)