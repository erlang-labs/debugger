%%
%% %CopyrightBegin%
%%
%% Copyright Ericsson AB 2000-2010. All Rights Reserved.
%%
%% The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved online at http://www.erlang.org/.
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.
%%
%% %CopyrightEnd%
%%

-module(bs_match_tail_SUITE).

-author('bjorn@erix.ericsson.se').
-export([all/1,init_per_testcase/2,fin_per_testcase/2,init_all/1,finish_all/1,
	 aligned/1,unaligned/1,zero_tail/1]).

-include("test_server.hrl").

all(suite) ->
    [{conf,init_all,cases(),finish_all}].

cases() ->
    [aligned,unaligned,zero_tail].

init_per_testcase(_Case, Config) ->
    test_lib:interpret(?MODULE),
    Dog = test_server:timetrap(?t:minutes(1)),
    [{watchdog,Dog}|Config].

fin_per_testcase(_Case, Config) ->
    Dog = ?config(watchdog, Config),
    ?t:timetrap_cancel(Dog),
    ok.

init_all(Config) when is_list(Config) ->
    ?line test_lib:interpret(?MODULE),
    ?line true = lists:member(?MODULE, int:interpreted()),
    ok.

finish_all(Config) when is_list(Config) ->
    ok.

aligned(doc) -> "Test aligned tails.";
aligned(Config) when list(Config) ->
    ?line Tail1 = mkbin([]),
    ?line {258,Tail1} = al_get_tail_used(mkbin([1,2])),
    ?line Tail2 = mkbin(lists:seq(1, 127)),
    ?line {35091,Tail2} = al_get_tail_used(mkbin([137,19|Tail2])),

    ?line 64896 = al_get_tail_unused(mkbin([253,128])),
    ?line 64895 = al_get_tail_unused(mkbin([253,127|lists:seq(42, 255)])),

    ?line Tail3 = mkbin(lists:seq(0, 19)),
    ?line {0,Tail1} = get_dyn_tail_used(Tail1, 0),
    ?line {0,Tail3} = get_dyn_tail_used(mkbin([Tail3]), 0),
    ?line {73,Tail3} = get_dyn_tail_used(mkbin([73|Tail3]), 8),

    ?line 0 = get_dyn_tail_unused(mkbin([]), 0),
    ?line 233 = get_dyn_tail_unused(mkbin([233]), 8),
    ?line 23 = get_dyn_tail_unused(mkbin([23,22,2]), 8),
    ok.

al_get_tail_used(<<A:16,T/binary>>) -> {A,T}.
al_get_tail_unused(<<A:16,_T/binary>>) -> A.

unaligned(doc) -> "Test that an non-aligned tail cannot be matched out.";
unaligned(Config) when list(Config) ->
    ?line {'EXIT',{function_clause,_}} = (catch get_tail_used(mkbin([42]))),
    ?line {'EXIT',{{badmatch,_},_}} = (catch get_dyn_tail_used(mkbin([137]), 3)),
    ?line {'EXIT',{function_clause,_}} = (catch get_tail_unused(mkbin([42,33]))),
    ?line {'EXIT',{{badmatch,_},_}} = (catch get_dyn_tail_unused(mkbin([44]), 7)),
    ok.

get_tail_used(<<A:1,T/binary>>) -> {A,T}.

get_tail_unused(<<A:15,_/binary>>) -> A.

get_dyn_tail_used(Bin, Sz) ->
    <<A:Sz,T/binary>> = Bin,
    {A,T}.

get_dyn_tail_unused(Bin, Sz) ->
    <<A:Sz,_T/binary>> = Bin,
    A.

zero_tail(doc) -> "Test that zero tails are tested correctly.";
zero_tail(Config) when list(Config) ->
    ?line 7 = (catch test_zero_tail(mkbin([7]))),
    ?line {'EXIT',{function_clause,_}} = (catch test_zero_tail(mkbin([1,2]))),
    ?line {'EXIT',{function_clause,_}} = (catch test_zero_tail2(mkbin([1,2,3]))),
    ok.

test_zero_tail(<<A:8>>) -> A.

test_zero_tail2(<<_A:4,_B:4>>) -> ok.

mkbin(L) when list(L) -> list_to_binary(L).
