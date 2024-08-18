using Dates, Base64, SHA
using JSON, HTTP, YAML

"""
    business

Default parameters.

Reference
- https://www.xfyun.cn/doc/tts/online_tts/API.html
"""

const business = Dict(
    "aue"    => "lame",
    "sfl"    => 1,
    "auf"    => "audio/L16;rate=16000",
    "vcn"    => "aisxping",
    "speed"  => 50,
    "volume" => 50,
    "pitch"  => 50,
    "bgs"    => 0,
    "tte"    => "utf8",
    "reg"    => "0",
    "rdn"    => "0"
)

"""
    create_url(APIKey, APISecret)

Create URL from APIKey and APISecret
Reference
- https://www.xfyun.cn/doc/tts/online_tts/API.html
"""
function create_url(APIKey, APISecret)
    request_line = "GET /v2/tts HTTP/1.1"
    url          = "wss://tts-api.xfyun.cn/v2/tts"
    host         = "ws-api.xfyun.cn"
    date         = string(Dates.format(Dates.now(), "e, dd u Y HH:MM:SS") * " GMT")
    signature_origin = "host: $(host)\ndate: $(date)\n$(request_line)"
    signature_sha    = hmac_sha256(collect(codeunits(APISecret)), signature_origin)
    signature_final  = base64encode(signature_sha)
    authorization_origin = """
        api_key=\"$(APIKey)\",
        algorithm=\"hmac-sha256\",
        headers=\"host date request-line\",
        signature=\"$(signature_final)\"
    """
    authorization_final = base64encode(authorization_origin)
    params = Dict(
        "authorization" => authorization_final,
        "date"          => date, 
        "host"          => host)
    wsUrl = string(merge(HTTP.URI(url), query = params))
    return wsUrl
end

"""
    create_parameters(text, business, APPID)

Create parameters from "text", "business" (parameters), and "APPID"

Reference
- https://www.xfyun.cn/doc/tts/online_tts/API.html
"""
function create_parameters(text, business, APPID)
    parameters = Dict(
        "common"   => Dict("app_id" => APPID),
        "business" => business,
        "data"     => Dict("text" => base64encode(text), "status" => 2)
        )
    parameters_json = JSON.json(parameters)
    return parameters_json
end

"""
    synthesize_audio(text; config = "config.yaml")

Create parameters from "text" and "config.yaml"

Reference
- https://www.xfyun.cn/doc/tts/online_tts/API.html

## Example

```julia
    synthesize_audio("张三吃掉了米饭和面条，还有一盆鱼")
```
"""
function synthesize_audio(text, file_name = missing; config = "config.yaml")

    # 1. Load "config.yaml" file and retrie parameters
    config = YAML.load_file(config)
    APPID, APIKey, APISecret = config["APPID"], config["APIKey"], config["APISecret"]
    newparameters = filter(((k, v), ) -> k .∈ Ref(keys(business)), config)

    # 2. Create_parameters
    parameters = create_parameters(text, merge(business, newparameters), APPID)

    # 3. Create url
    wsUrl  = create_url(APIKey, APISecret)
    
    # 4. Create file name for the generate audio file
    ismissing(file_name) && (file_name = "$text.mp3")

    # 5. Do the generating
    WebSockets.open(wsUrl) do ws
        isfile(file_name) && rm(file_name)
        WebSockets.send(ws, parameters)
        for msg in ws
            msg = JSON.parse(String(msg))
            audio = msg["data"]["audio"]
            audio = base64decode(audio)
            open(file_name, "a") do f
                write(f, audio)
            end
        end
    end
end