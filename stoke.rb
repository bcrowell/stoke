#!/usr/bin/ruby

require 'date'

def main
  routes,times = read_data()
  pr,routes,times = process_data(routes,times)

  print_all(pr,routes,times)

  if true then
    csv_report_one_route("stoke.csv",pr,routes,times,"vivian")
    # This doesn't get graphed, just produces the csv file.
  end

  eps = 1.0/300.0 # slightly more than one day
  start_rel = -2.0 # only go back to this number of years before today; -2.0 works well
  end_rel = 0.0+eps
  graph_all_routes('pdf',"stoke",pr,routes,times,start_rel,end_rel)

end

def csv_report_one_route(csv_file,pr,routes,times,selected_route)
  csv = ''
  times.each { |x|
    route,date,minutes = x
    if route!=selected_route then next end
    yr = date_to_year_and_frac(date)
    row = []
    row.push(("%8.3f" % [yr.to_s]))
    energy,power = energy_and_power(routes,selected_route,minutes)
    row.push(("%3d" % [power]))
    csv = csv + row.join(',') + "\n"
  }
  File.open(csv_file,'w') { |f|
    f.print csv
  }
end

def graph_all_routes(file_format,file_stem,pr,routes,times,start_rel,end_rel)
  # file format can be svg or pdf
  filename = file_stem + "." + file_format
  r = "#{file_format}(\"#{filename}\")\n"
  v = [] # names of variables holding routes
  t_var = [] # ... and times
  min_t = 9999.9
  max_t = -9999.9
  min_y = 9999.9
  max_y = -9999.9
  today = date_to_year_and_frac(Date.today)
  route_type = []
  routes.keys.each { |name|
    route_type.push(find_route_type(routes,name))
    if name=~/\A[a-zA-Z]/ then var_name=name else var_name="v_"+name end # for routes like "400", make an array called "v_400"
    t_var_name = "t_"+name
    v.push(var_name)
    t_var.push(t_var_name)
    t = []
    a = []
    times.each { |x|
      route_raw,date,minutes = x
      if route_raw==name then
        energy,power = energy_and_power(routes,name,minutes)
        yr = date_to_year_and_frac(date)
        if t.length>0 and t[-1].to_f>yr then die("times out of order, #{date}") end
        if yr<today+start_rel or yr>today+end_rel then next end # qwe
        t.push("%8.3f" % [yr])
        a.push("%3d" % [power])
        if yr<min_t then min_t = yr end
        if yr>max_t then max_t = yr end
        if power<min_y then min_y = power end
        if power>max_y then max_y = power end
      end
    }
    r = r + t_var_name + ' <- c(' +t.join(',')+')'+"\n"
    r = r +   var_name + ' <- c(' +a.join(',')+')'+"\n"
  }
  r = r + "plot(c(#{min_t},#{max_t}),c(#{min_y},#{max_y}),type=\"n\",xlab=\"date\",ylab=\"power (millikipchoge)\")\n" # empty frame and axes
  i = 0
  count_routes_of_type = {}
  dash_types = ['',  ',lty="42"',  ',lty="11"',  ',lty="4121"']
  dash_type_description = ['____',  '- - ',  '....',  '-.-.']
  v.each { |var_name|
    rt = route_type[i]
    if !(count_routes_of_type.has_key?(rt)) then count_routes_of_type[rt]=0 end
    count_routes_of_type[rt] = count_routes_of_type[rt]+1
    dashes = ''
    dash_description = '____'
    if count_routes_of_type[rt]<=4 then
      dashes = dash_types[count_routes_of_type[rt]-1]
      dash_description = dash_type_description[count_routes_of_type[rt]-1]
    end
    color = route_type_to_color(rt)
    r = r + "lines(#{t_var[i]},#{var_name},col=#{color} #{dashes})\n"
    r = r + "points(#{t_var[i]},#{var_name},col=#{color})\n"
    print("#{var_name} #{color_description(color)} #{dash_description}\n")
    i=i+1
  }
  r = r + "garbage <- dev.off()\n" # https://stackoverflow.com/a/750710/1142217
  r_file = "temp.r"
  File.open(r_file,'w') { |f|
    f.print r
  }
  system("R --quiet --slave --no-save --no-restore-data <#{r_file}")
  print "Wrote #{filename}\n"
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

def find_route_type(routes,name)
  flat_cf = 2.0 # tunnel is 1.8
  miles,cf = routes[name]
  if miles<=8.5 && cf>flat_cf && cf<10.0 then return "short_trail" end
  if miles>8.5 && cf>flat_cf && cf<10.0 then return "long_trail" end
  if miles<=1.0 then return "sprint" end
  if miles<=13.5 && cf<flat_cf then return "short_road" end
  if miles>13.5 && cf<flat_cf then return "long_road" end
  if cf>10 then return "mountain" end
  return "misc"
end

# default color palette for R
# 1= "black"   "red"     "green"  "blue"    "cyan"    "magenta" "yellow"  "gray"   
def color_description(color)
  return [nil,"black",  "red",    "green", "blue",   "cyan",   "magenta", "yellow", "gray"][color]
end

def route_type_to_color(t)
  if t=="sprint" then return 2 end
  if t=="short_trail" then return 3 end
  if t=="long_trail" then return 4 end
  if t=="mountain" then return 1 end
  if t=="short_road" then return 5 end
  if t=="long_road" then return 6 end
  if t=="misc" then return 7 end
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
