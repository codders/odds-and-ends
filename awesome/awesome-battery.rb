#!/usr/bin/ruby

$pidfile = "/home/at/var/run/awesome_battery.pid"
$battery_dir = "/sys/class/power_supply/"
$history_size = 50
$sleep_period = 2

class Battery

  attr_reader :remaining

  def initialize(filename)
    @data = []
    @filename = filename
    @max_energy = read_file_contents("#{@filename}/energy_full").to_i
  end

  def current_energy()
    return read_file_contents("#{@filename}/energy_now").to_i
  end

  def rate
     return (@data[-1] - @data[0]).to_f / ($sleep_period * @data.length)
  end

  def update
    current = current_energy()
    @data.unshift(current)
    if @data.length > $history_size
      @data.delete_at(-1)
    end
    @remaining = current.to_f / (rate * 60)
    self
  end

  def to_s
    if @remaining.finite?
      percent = ((current_energy.to_f * 100.0)/@max_energy)
      color = '#0f0'
      if percent < 50
        color = '#ff0'
      end
      if percent < 10
        color = '#f00'
      end
      if @remaining >= 0
        mins = remaining.to_i
        hours = mins / 60
        "<span color=\"#{color}\"><b>↓</b></span>%d:%02d" % [ hours, mins % 60 ]
      else
        "<span color=\"#{color}\"><b>↑</b></span>%d%%" % percent
      end
    else
      '<span color="#0f0"><b>▮</b></span>'
    end
  end

end

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

def awesome_print(data)
  return "mybatterybox:set_markup('#{data.gsub(/'/, "&apos;")}')\n"
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

@batteries = []
power_folder = Dir.new($battery_dir)
power_folder.select { |f| f.start_with?("BAT") }.each do |f|
  @batteries << Battery.new("#{$battery_dir}/#{f}") 
end

while true
  sleep $sleep_period
  battery_string = @batteries.map { |b| b.update() }.collect { |b| b.to_s }.join("  ")
  write_to_pipe("awesome-client", battery_string)
end


