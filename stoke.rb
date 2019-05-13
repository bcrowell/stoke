#!/usr/bin/ruby

require 'date'

def main
  routes,times = read_data()
  pr,routes,times = process_data(routes,times)

  # print_all(pr,routes,times)

  csv = csv_report(pr,routes,times)
  File.open("stoke.csv",'w') { |f|
    f.print csv
  }

end

def csv_report(pr,routes,times)
  csv = routes.keys.unshift('date').join(',')+"\n"
  times.each { |x|
    route,date,minutes = x
    yr = date_to_year_and_frac(date)
    row = []
    row.push(("%8.3f" % [yr.to_s]))
    routes.keys.each { |name|
      if route==name then
        energy,power = energy_and_power(routes,name,minutes)
        row.push("%3d" % [power])
      else
        row.push('')
      end
    }
    csv = csv + row.join(',') + "\n"
  }
  return csv
end

def print_all(pr,routes,times)
  times.each { |time|
    name,date,minutes = time
    energy,power = energy_and_power(routes,name,minutes)
    is_pr = (pr[name][0]==date)
    if is_pr then
      suffix = "*"
    else
      suffix = ""
    end
    print "#{"%-20s" % [name]} #{date}, energy=#{"%5.3f" % [energy]}, power=#{"%3d" % [power]} #{suffix}\n"
  }
end

def energy_and_power(routes,name,minutes)
  miles,cf = routes[name]
  energy = miles_to_energy(miles,cf) # energy in units of marathons
  power = time_to_mk(energy,minutes) # power in millikipchoges
  return [energy,power]
end

def process_data(routes,times)
  pr = {}
  times.each { |time|
    route,date,tt = time
    if pr.has_key?(route) && pr[route][1]<tt then next end
    pr[route] = [date,tt]
  }
  return [pr,routes,times]
end

# {"400"=>[0.249, 0.0, {}], "mile"=>[1.0, 0.0, {}], "lake"=>[5.72, 3.4, {}], "great"=>[8.31, 3.5, {}], "casolero"=>[14.12, 4.1, {}], "hill"=>[8.39, 3.8, {}], "b2"=>[14.48, 3.8, {}], "tunnel"=>[12.88, 1.8, {}], "wilson"=>[6.62, 58.1, {}], "3t"=>[17.06, 34.8, {}], "vivian"=>[9.04, 48.3, {}], "south_fork"=>[9.43, 41.2, {}]}
# [["wilson", #<Date: 2019-01-01 ((2458485j,0s,0n),+0s,2299161j)>, 121.0]]
def read_data
  r = read_table("routes.tab",['string','float','float'])
  routes = {}
  r.each { |route|
    name,distance,cf,opt = route
    routes[name] = [distance,cf,opt]
  }
  t = read_table("times.tab",['string','date','time'])
  times = []
  t.each { |time|
    name,date,tt = time
    if !(routes.has_key?(name)) then die("unrecognized name for route: #{name}") end
    distance = routes[name][0]
    # Figure out based on sanity whether time is in seconds or minutes. Convert to minutes.
    if tt/distance>50.0 then # more than 50 min per mile can't be right
      tt = tt/60.0 # convert seconds to minutes
    else
      tt = tt.to_f
    end
    times.push([name,date,tt])
  }
  return [routes,times]
end

def die(message)
  $stderr.print message+"\n"
  exit(-1)
end

def read_table(filename,template)
  n_cols = template.length
  result = []
  File.open(filename,'r') { |f|
    f.each_line {|line|
      orig = line.clone.sub!(/\n$/,'')
      line.gsub!(/#.*/,"") # trim comments; note that this doesn't allow # in string data, which is OK for my application
      line.gsub!(/\s+\Z/,"") # trim trailing whitespace
      line.gsub!(/\A\s+/,"") # trim leading whitespace
      if line=~/\A\s*\Z/ then next end # skip blank lines
      if line=~/(.*)({.*)/ then
        cols,opt = $1,$2
      else
        cols,opt = line,{}
      end
      row = cols.split(',')
      if row.length!=template.length then die("syntaxt error in file #{filename}, line=#{orig}, expected #{n_cols} columns, got #{row.length}") end
      col = 0
      row.each { |x|
        cast=to_type(row[col],template[col])
        if cast.nil? then
          die("syntaxt error in file #{filename}, line=#{orig}, column #{col}, value=#{row[col]}, expected type #{template[col]}")
        else
          row[col] = cast
        end
        col=col+1
      }
      row.push(opt)
      result.push(row)
    }
  }
  return result
end

def to_type(s,t)
  if defined?(@current_year).nil?
    @current_year = nil
  end
  if t=='float' then
    if s =~ /^\s*[+-]?((\d+_?)*\d+(\.(\d+_?)*\d+)?|\.(\d+_?)*\d+)(\s*|([eE][+-]?(\d+_?)*\d+)\s*)$/ then # https://stackoverflow.com/a/1072196/1142217
      return s.to_f
    else
      return nil
    end
  end
  if t=='date' then
    if !(s=~/(19|20)\d\d/) then
      if @current_year.nil? then return nil end
      s = @current_year.to_s+" "+s
    end
    d = Date.parse(s)
    @current_year = d.year
    return d
  end
  if t=='time' then
    x = 0.0
    s.split(':').map {|k| k.to_f} .each { |k|
      if k<0 or k>59 then return nil end
      x = x*60.0+k
    }
    return x
  end
  # fall through to default, do nothing to the string
  return s
end

def marathon
  return 26.219 # length of marathon, in miles
end


def miles_to_energy(miles,cf) # returns energy in units of marathons
  return (miles/marathon())*(1.0+cf/(100.0-cf))
end

def time_to_mk(energy,minutes) # returns power in units of millikipchoges, where 1 kipchoge is the energy to run 1 marathon in 2 hours
  # input energy is in units of marathons
  return 1000.0*energy/(minutes/120.0)
end

def date_to_year_and_frac(date)
  jd = date.mjd-Date.parse('2000 jan 1').mjd; # days since turn of the century
  y = 2000+(jd.to_f/365.25) # sloppy way of calculating what is very nearly the year plus fraction of a year
  return y  
end

main
