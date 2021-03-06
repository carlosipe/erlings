-module(map_test).

-include_lib("eunit/include/eunit.hrl").

merge_map_empty_test() ->
    Map = #{a => 1, b => 2, c => 3},
    ?assertEqual(Map, map:merge(#{}, Map)),
    ?assertEqual(Map, map:merge(Map, #{})).

merge_map_update_test() ->
    Map1 = #{a => 1, b => 2, c => 3},
    Map2 = #{b => 6, d => 4},
    Map3 = #{a => 1, b => 6, c => 3, d => 4},
    ?assertEqual(Map3, map:merge(Map1, Map2)).

mapping_a_map_empty_map_test() ->
    F = fun(X) -> X + 1 end,
    ?assertEqual(#{}, map:map(F, #{})).

mapping_a_map_add_1_test() ->
    F = fun(X) -> X + 1 end,
    Map = #{a => 1, b => 2, c => 3},
    Res = #{a => 2, b => 3, c => 4},
    ?assertEqual(Res, map:map(F, Map)).

list_to_map_test() ->
    List = [2, 23, a],
    Map = #{1 => 2, 2 => 23, 3 => a},
    ?assertEqual(Map, map:to_map(List)).

list_to_map_empty_test() ->
    ?assertEqual(#{}, map:to_map([])).
