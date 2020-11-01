# EP: есть ли аналог в julia для `import ZipFile as zf`?
using ZipFile
using ProgressMeter
using JSON3
using Geodesy


"""
Save zip file from URL to local disk. 
Overwrite when force = true.
"""
function save_local(url, zip_file_path, force = false)
    if !isfile(zip_file_path) | force
        @info "Downloading raw data from $(url)."
        download(url, zip_file_path)
    else
        @info "File $(zip_file_path) already downloaded."
    end
end


"""
Read list of JSON objects from zip file.
"""
function read_local(zip_file_path)
    result = []
    r = ZipFile.Reader(zip_file_path)
    n = length(r.files)
    @info "Processing $(n) rides from $(zip_file_path)"
    @showprogress for f in r.files
        holder = Vector{UInt8}(undef, f.uncompressedsize)
        read!(f, holder)
        push!(result, JSON3.read(holder))
    end
    close(r)
    return result
end

RAW_DATA_URL = ("https://dl.dropboxusercontent.com" *
    "/sh/hibzl6fkzukltk9/AABSMicBJlwMnlmA3ljt1uY5a" *
    "/data_samples-json2.zip")
LOCAL_ZIPFILE = "data_samples-json2.zip"

save_local(RAW_DATA_URL, LOCAL_ZIPFILE)
# May comment/uncomment for use in REPL to save time
raw_rides = read_local(LOCAL_ZIPFILE)
@assert length(raw_rides) == 3585

# EP: может быть JSON типа raw_rides - нужно как-то новый тип создать?
function car_id(raw_ride)
    raw_ride.info.car_id
end

function car_ids(raw_rides)
    unique(map(car_id, raw_rides))
end    

ids = car_ids(raw_rides)
@assert length(ids) == 131

struct Location 
    timestamp::Int
    coord::LatLon{Float64}
end
Location(xs::AbstractVector) = Location(xs[1], LatLon(xs[3], xs[2]))

Route = Array{Location,1}

function make_route(raw_ride)
    map(Location, raw_ride.data)
end

route5 = make_route(raw_rides[5])

# EP: Эта часть занимает 1:30, подозрительно много
routes = @showprogress map(make_route, raw_rides) 

length(routes)

typeof(routes)
#Array{Array{Location,1},1}
#EP Может ли выводить тип Array{Route,1}?
