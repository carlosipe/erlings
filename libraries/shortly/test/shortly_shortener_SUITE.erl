-module(shortly_shortener_SUITE).

-include_lib("common_test/include/ct.hrl").

-compile(export_all).
-compile(nowarn_export_all).

all() ->
    [test_notfound,
     test_created,
     test_ok,
     test_redirect,
     test_ws].

init_per_testcase(_,Config) ->
    application:ensure_all_started(shortly),
    application:ensure_all_started(gun),
    Config.

end_per_testcase(_, Config) ->
    application:stop(shortly),
    application:stop(gun),
    Config.

test_notfound(_) ->
    NewUrl = url("http://not.com/existent"),
    {404, _,  #{}} = do_get_request(NewUrl).

test_created(_) ->
    NewUrl = url("http://new.created.com/"),
    {201, _, #{<<"url">> := _}} = do_post_request(NewUrl).

test_ok(_) ->
    LongUrl = url("htts://random.org"),
    {201, _, #{<<"url">> := ShortUrl}} = do_post_request(LongUrl),
    {200, _, #{<<"url">> := ShortUrl}} = do_post_request(LongUrl).

test_redirect(_) ->
    LongUrl = url("http://example.com/testing_redirect"),
    {201, _, #{<<"url">> := ShortUrl}} = do_post_request(LongUrl),
    {302, Headers, #{<<"url">> := LongUrl}} = do_get_request(ShortUrl),
    RedirectionHeader = list_to_binary(proplists:get_value("location", Headers)),
    LongUrl = RedirectionHeader.

test_ws(_) ->
    WsConn = ws_connect("/news"),
    LongUrl = url("http://random.com/long"),
    {_, _, #{<<"url">> := ShortUrl}} = do_post_request(LongUrl),
    JsonResponse = ws_get(WsConn),
    Response = json_to_map(JsonResponse),
    #{<<"long_url">> := LongUrl} = Response,
    #{<<"short_url">> := ShortUrl} = Response,
    ws_terminate(WsConn).

get_request_url(Url) ->
    BinaryReqUrl = iolist_to_binary([<<"http://localhost:8080/">>, Url]),
    UrlStr = binary_to_list(BinaryReqUrl),
    UrlStr.

json_to_map(In) ->
    InBinary = case is_list(In) of
                   true -> list_to_binary(In);
                   _ -> In
               end,
    case jsx:is_json(InBinary) of
        true -> jsx:decode(InBinary, [return_maps]);
        _ -> #{}
    end.

do_post_request(Url) ->
    ReqUrl = get_request_url(Url),
    {ok, {{_, StatusCode, _}, Headers, Body}} =
        httpc:request(post, {ReqUrl, [], [], []}, [], []),
    {StatusCode, Headers, json_to_map(Body)}.

do_get_request(Url) ->
    ReqUrl = get_request_url(Url),
    {ok, {{_, StatusCode, _}, Headers, Body}} =
        httpc:request(get, {ReqUrl, []},[{autoredirect,false}],[]),
    {StatusCode, Headers, json_to_map(Body)}.

url(Url) ->
    StringUrl = http_uri:encode(Url),
    list_to_binary(StringUrl).

ws_connect(Path) ->
	{ok, Pid} = gun:open("127.0.0.1", 8080, #{retry=>0}),
	{ok, http} = gun:await_up(Pid),
	Ref = monitor(process, Pid),
	gun:ws_upgrade(Pid, Path, [], #{compress => true}),
	receive
		{gun_ws_upgrade, Pid, ok, _} ->
			ok;
		_ -> error(failed)
	end,
	{Pid, Ref}.

ws_get({Pid,_}) ->
    receive
        {gun_ws, Pid, {text, Text}} -> Text;
        _ ->  error(failed)
    after 5000 ->
            error(timout)
    end.
    
ws_terminate({Pid, Ref}) ->
    demonitor(Ref),
    gun:close(Pid).
