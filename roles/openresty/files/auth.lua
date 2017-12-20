local function exit_401(body)
    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.header["Content-Type"] = "text/html; charset=UTF-8"
    ngx.header["WWW-Authenticate"] = "oauthjwt"
    ngx.say(body)
    return ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

local function exit_403()
    ngx.status = ngx.HTTP_FORBIDDEN
    ngx.header["Content-Type"] = "text/html; charset=UTF-8"
    ngx.say(BODY_403_ERROR_RESPONSE)
    return ngx.exit(ngx.HTTP_FORBIDDEN)
end

local function validate_token()
    local token = ngx.var.cookie_token
    local host = ngx.var.host

    local uri = "http://127.0.0.1/apis/cmss.com/v1/verify?token=" .. token

    local http = require "resty.http"
    local httpc = http.new()
    local res, err = httpc:request_uri(uri, {
        method = "GET",
    })

    if res.status == 401 then
      err = res.body
      return "", err
    end

    if res.status ~= 200 then
        return "", nil
    end

    local cjson = require "cjson"
    local data = cjson.decode(res.body)
    ngx.log(ngx.DEBUG, "validating the token of " .. data["name"])
    return data["name"], nil
end

local function validate_authority(user)
    local cluster = ngx.var.cookie_cluster
    local namespace = ngx.var.cookie_namespace
    local resource = ngx.var.uri
    local action = ngx.var.request_method
    local host = ngx.var.host

    if (resource == "/apis/cmss.com/v1/authority") and (action == "POST") then
        return
    end

    local uri = "http://127.0.0.1/apis/cmss.com/v1/authchk"

    local http = require "resty.http"
    local httpc = http.new()
    ngx.log(ngx.DEBUG, uri)
    local res, err = httpc:request_uri(uri, {
        method = "GET",
        query = {
            user = user,
            cluster = cluster,
            namespace = namespace,
            resource = resource,
            action = action,
        },
    })

    local cjson = require "cjson"
    local data = cjson.decode(res.body)
    if not data["authorized"] then
        return exit_403()
    end
end

local function validate_token_and_authority()
    user, err = validate_token()
    if err then
      return exit_401(err)
    end

    if not user then
        return exit_401("your token expired")
    end

    validate_authority(user)
end


local function get_name()

     if ngx.var.request_method == "POST" and ngx.var.request_uri ~= "/image/login" and (not(string.find(ngx.var.request_uri,"/logmanage/")))
     then 
        ngx.req.read_body()
        local reqdata = ngx.req.get_body_data()
        local cjson = require "cjson"
        local string = require "string"
        local data = cjson.decode(reqdata)
        local post_body = "default"
        local kind = ""
        if ngx.var.request_uri == "/apis/cmss.com/v1/user"
        then 
            post_body = data["username"]
        elseif ngx.var.request_uri == "/apis/cmss.com/v1/group"
             then 
               post_body = data["groupname"]
        elseif ngx.var.request_uri == "/apis/cmss.com/v1/resource"
             then 
               post_body = data["name"]
        elseif ngx.var.request_uri == "/apis/cmss.com/v1/rule"
             then 
               post_body = data["name"]
        elseif ngx.var.request_uri == "/apis/cmss.com/v1/role"
             then 
               post_body = data["name"]
        elseif ngx.var.request_uri == "/apis/cmss.com/v1/authority"
             then 
               post_body = data["conditions"]["namespace"] .. "/" .. data["object"]  
         elseif string.find(ngx.var.request_uri,"/conductor/api/v1/_raw/") 
             then
               post_body = data["metadata"]["name"]
         elseif ngx.var.request_uri == "/conductor/api/v1/appdeploymentfromfile"
             then
               local content = data["content"]
               data = cjson.decode(content)
               if data["kind"] == "List" 
               then
                  kind = data["items"][1]["kind"]
                  post_body = data["items"][1]["metadata"]["name"] .. ":" .. kind
               else
                  kind = data["kind"]
                  post_body = data["metadata"]["name"] .. ":" .. kind
               end
        end
           return post_body
        else return nil
     end
end

       
local _M = {}
_M.validate_token_and_authority = validate_token_and_authority
_M.get_name = get_name
return _M
