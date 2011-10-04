% Licensed under the Apache License, Version 2.0 (the "License"); you may not
% use this file except in compliance with the License. You may obtain a copy of
% the License at
%
%   http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
% WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
% License for the specific language governing permissions and limitations under
% the License.

-module(test_util).

-export([init_code_path/0]).
-export([source_file/1, build_file/1, config_files/0]).
-export([request/3, request/4]).

init_code_path() ->
    code:load_abs("apps/couch/test/etap/etap").

source_file(Name) ->
    filename:join(["apps/couch", Name]).

build_file(Name) ->
    filename:join(["rel/overlay", Name]).

config_files() ->
    [
        build_file("etc/default.ini"),
        build_file("etc/local.ini"),
        source_file("test/etap/random_port.ini")
    ].

request(Url, Headers, Method) ->
    request(Url, Headers, Method, []).

request(Url, Headers, Method, Body) ->
    request(Url, Headers, Method, Body, 3).

request(_Url, _Headers, _Method, _Body, 0) ->
    {error, request_failed};
request(Url, Headers, Method, Body, N) ->
    case code:is_loaded(ibrowse) of
    false ->
        {ok, _} = ibrowse:start();
    _ ->
        ok
    end,
    case ibrowse:send_req(Url, Headers, Method, Body) of
    {ok, Code0, RespHeaders, RespBody0} ->
        Code = list_to_integer(Code0),
        RespBody = iolist_to_binary(RespBody0),
        {ok, Code, RespHeaders, RespBody};
    {error, {'EXIT', {normal, _}}} ->
        % Connection closed right after a successful request that
        % used the same connection.
        request(Url, Headers, Method, Body, N - 1);
    Error ->
        Error
    end.
