#!/usr/bin/ruby
#

$pidfile = "/home/at/var/run/awesome_battery.pid"
$battery_dir = "/sys/class/power_supply/BAT1"
$history_size = 50
$sleep_period = 2

def read_file_contents(filename)
  begin
    f = File.new(filename, "r")
    data = f.gets
    f.close()
    return data.strip
  rescue
    #puts "Error reading from #{filename}: #{$!}"
    return nil
  end
end

def write_file_contents(filename, data)
    f = File.new(filename, "w")
    f.write(data)
    f.close()
end

def current_energy()
  return read_file_contents("#{$battery_dir}/energy_now") || read_file_contents("#{$battery_dir}/charge_now")
end

def rate(array)
   return (array[-1] - array[0]).to_f / ($sleep_period * array.length)
end

def awesome_print(data)
  return "mybatterybox.text='#{data.gsub(/'/, "&apos;")}'\n"
end

def write_to_pipe(command, data)
  f = IO.popen(command, "w")
  f.write(awesome_print(data))
  f.close()
end

if File.exists?($pidfile)
    pid = read_file_contents($pidfile)
    if system("kill -0 #{pid} 2> /dev/null")
      puts "Already running"
      exit 1
    else
      puts "Removed bogus lock file"
    end
end
write_file_contents($pidfile, "#{$$}\n")

full_battery = read_file_contents("#{$battery_dir}/energy_full") || read_file_contents("#{$battery_dir}/charge_full")
puts "Full: #{full_battery}"
data = Array.new()



while true
  sleep $sleep_period
  current = current_energy().to_i
  data.unshift(current)
  if data.length > $history_size
    data.delete_at(-1)
  end
  present_rate = rate(data)
  remaining = current.to_f / (present_rate * 60)
  write_to_pipe("awesome-client", "%.2f mins" % remaining)
end


