using BrainFlow
using DataFrames
using VegaLite
using Query

BrainFlow.enable_dev_logger(BrainFlow.BOARD_CONTROLLER)

params = BrainFlowInputParams()
board_shim = BrainFlow.BoardShim(BrainFlow.GFORCE_PRO_BOARD, params)

BrainFlow.prepare_session(board_shim)
BrainFlow.start_stream(board_shim)
sleep(5)
BrainFlow.stop_stream(board_shim)
data = BrainFlow.get_board_data(board_shim)
BrainFlow.release_session(board_shim)

emg_channels = BrainFlow.get_emg_channels(BrainFlow.GFORCE_PRO_BOARD)
emg_data = data[emg_channels,:]

emg_names = Symbol.(["emg$x" for x in 1:8])
df = DataFrame(emg_data')
DataFrames.rename!(df, emg_names)

sampling_rate = BrainFlow.get_sampling_rate(BrainFlow.GFORCE_PRO_BOARD)
nrows = size(df)[1]
df.time = (1:nrows)/nrows*5

df2 = stack(df, 1:8)
rename!(df2, [:time, :channel, :value])

df2 |> @filter(_.time > 0.2) |>
@vlplot(
    :line,
    x=:time,
    y=:value,
    row=:channel,
    width=400,
    height=25
)
