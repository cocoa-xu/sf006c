defmodule Cirlute.SF006C do
  @moduledoc """
  Elixir driver for SunFounder SF006C Servo.
  """
  @min_angle 0
  @max_angle 180

  alias __MODULE__, as: T

  @behaviour Cirlute.Servo

  @enforce_keys [
    :pwm_module,
    :pwm_driver,
    :pwm_channel,
    :pwm_frequency,
    :offset,
    :min_pulse_width,
    :max_pulse_width
  ]
  defstruct pwm_module: nil,
            pwm_driver: nil,
            pwm_channel: 0,
            pwm_frequency: 60,
            lock: true,
            offset: 0,
            min_pulse_width: 600,
            max_pulse_width: 2400,
            default_pulse_width: 1500,
            pulse_width: 1500

  @type pwm_opt() :: {term(), non_neg_integer(), pos_integer(), number()}
  @type servo_opts() :: [pwm_opt: pwm_opt()]

  @doc """
  Initialise SF006C

  - **channel**: PWM channel.
  - **opts**:
      - **pwm_opt**: `{Cirlute.PWM, pwm_address, pwm_i2c_bus, pwm_freq}`
  """
  @spec new(non_neg_integer(), servo_opts()) :: {:ok, term()} | {:error, term()}
  def new(channel, opts) do
    with [pwm_module, pwm_address, pwm_i2c_bus, pwm_freq] <- Tuple.to_list(opts[:pwm_opts] || {:error, "invalid pwm_opts"}),
         {:ok, pwm_driver} <- Kernel.apply(pwm_module, :new, [pwm_address, pwm_i2c_bus, pwm_freq]) do
      {:ok,
       %T{
         pwm_module: pwm_module,
         pwm_driver: pwm_driver,
         pwm_channel: channel,
         pwm_frequency: pwm_freq,
         lock: opts[:lock] || true,
         offset: opts[:offset] || 0,
         min_pulse_width: opts[:min_pulse_width] || 600,
         max_pulse_width: opts[:max_pulse_width] || 2400,
         default_pulse_width: opts[:default_pulse_width] || 1500,
         pulse_width: 1500
       }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Set servo angle

  - **self**: Cirlute.SF006C instance
  - **angle**: requested angle
  """
  @spec set_angle(term(), number()) :: {:ok, term()} | {:error, term()}
  def set_angle(self = %T{}, angle) when is_number(angle) and angle >= @min_angle and angle <= @max_angle do
    offset = angle_to_analog(self, angle) + self.offset

    with :ok <-
           Kernel.apply(self.pwm_module, :set_pwm, [
             self.pwm_driver,
             self.pwm_channel,
             offset
           ]) do
      {:ok, %T{self | pulse_width: offset}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def set_angle(self = %T{}, angle) when is_integer(angle) and angle > @max_angle do
    set_angle(self, @max_angle)
  end

  def set_angle(self = %T{}, angle) when is_integer(angle) and angle < @min_angle do
    set_angle(self, @min_angle)
  end

  defp map_value(x, in_min, in_max, out_min, out_max) do
    (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
  end

  defp angle_to_analog(self = %T{}, angle) do
    pulse_width = map_value(angle, @min_angle, @max_angle, self.min_pulse_width, self.max_pulse_width)
    min_pwm = Kernel.apply(self.pwm_module, :min_pwm, [])
    max_pwm = Kernel.apply(self.pwm_module, :max_pwm, [])
    pwm_levels = max_pwm - min_pwm + 1
    trunc(pulse_width / 1_000_000.0 * self.pwm_frequency * pwm_levels)
  end
end
