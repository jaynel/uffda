%% @doc
%%   The system suite tests the ability of uffda to handle multiple services
%%   which are supervised for restart and are cycling through availability.
%%
%%   The following properties are tested for a full system:
%%
%%   <ol>
%%     <li>A single supervisor with M of N services killed and no restarts.</li>
%%     <li>A single supervisor with M of N services killed and 3 restarts.</li>
%%     <li>A root supervisor with two children which are supervisors of services
%%         and has a lower supervisor restart.</li>
%%   </ol>
%% @end
-module(uffda_system_SUITE).
-vsn('').

-export([all/0, groups/0,
         init_per_suite/1,    end_per_suite/1,
         init_per_group/1,    end_per_group/1,
         init_per_testcase/2, end_per_testcase/2
        ]).

-export([
         single_no_restart/1, single_with_restart/1, tree_restart/1, dsl_first_run/1
        ]).


-include("uffda_common_test.hrl").
-type test_group() :: atom().

-spec all() -> [{group, test_group()}].
%% @doc
%%   All testcase groups that are run.
%% @end
all() -> [{group, supervised_services}, dsl_first_run].

-spec groups() -> [{atom(), [atom()], [atom()]}].
%% @doc
%%   Testcases are grouped so that a failure can save time.
%% @end
groups() -> [
             {supervised_services, [sequence],
              [single_no_restart,  single_with_restart,  tree_restart]}
            ].

-type config() :: proplists:proplist().

-spec init_per_suite(config()) -> config().
%% @doc
%%   One time initialization before executing all testcases in this suite.
%% @end
init_per_suite(Config) -> Config.

-spec end_per_suite(config()) -> config().
%% @doc
%%   One time cleanup after executing all testcases in this suite.
%% @end
end_per_suite(Config) -> Config.

-spec init_per_group(config()) -> config().
%% @doc
%%   One time initialization before executing a group in this suite.
%% @end
init_per_group(Config) -> Config.

-spec end_per_group(config()) -> config().
%% @doc
%%   One time cleanup after executing a group in this suite.
%% @end
end_per_group(Config) -> Config.

-spec init_per_testcase(module(), config()) -> config().
%% @doc
%%   Initialization before executing each testcase in this suite.
%% @end
init_per_testcase(_TestCase, Config) ->
    ok = uffda:start(),
    Config.

-spec end_per_testcase(module(), config()) -> ok.
%% @doc
%%   Cleanup after executing each testcase in this suite.
%% @end
end_per_testcase(_TestCase, _Config) ->
    uffda:stop().

-spec single_no_restart(config()) -> true.
%% @doc
%%   A single supervisor with no restarts managing multiple
%%   services which experience failure.
%% @end
single_no_restart(_Config) ->
    true.

-spec single_with_restart(config()) -> true.
%% @doc
%%   A single supervisor with restarts managing multiple
%%   services which experience failure.
%% @end
single_with_restart(_Config) ->
    true.

-spec tree_restart(config()) -> true.
%% @doc
%%   A tree of 3 processes with restarts that manages
%%   2 groups of services and experiences repeated failure
%%   of a service which takes out its parent. The restart
%%   logic uses the knowledge of restart to have a different
%%   behavior after subsequent restarts.
%% @end
tree_restart(_Config) ->
    true.

-spec dsl_first_run(config()) -> true.
%% @doc
%%   A check that the random generation of programs works
%%   properly.$
%% @end
dsl_first_run(_Config) ->
    Gen_Test = ?FORALL(Prog, gen_prog(),
        begin
           _NewProg = tree_processing:extract_tree_and_events({ok, Prog}),
           ok = uffda_dsl:run_program(Prog),
           {{startup, Tree}, _} = Prog,
           uffda_dsl:clean_up(Tree),
           true
        end),
    true = proper:quickcheck(Gen_Test, ?PQ_NUM(30)).

% @doc
% Generates a valid program to be processed further.
% @end
gen_prog() ->
    ?LET(Tree, ?SUCHTHAT(T, gen_tree_root(), uffda_dsl:unique_names(T)),
        begin
            Workers = uffda_dsl:extract_workers(Tree),
            case Workers of
                [] -> {{startup, Tree}, {actions, []}};
                _ -> ?LET(Actions,
                          list(tuple([union(Workers), gen_rwe()])),
                          {{startup, Tree}, {actions, Actions}})
            end
        end).

%% @doc
%%  Root of a randomly generated tree.
%% @end
gen_tree_root() ->
    tuple([node, gen_super(), list(tuple([leaf, gen_wos()]))]).

%% @doc
%% Makes a random choice between ending the tree or continuing it
%% to fill it out.
%% @end
gen_tree() ->
    Leaf = tuple([leaf, gen_wos()]),
    Node = ?LAZY(tuple([node, gen_super(), list(gen_tree())])),
    weighted_union([{20, Leaf}, {1, Node}]).

%% @doc
%% A worker or a supervisor.
%% @end
gen_wos() ->
    union([{supervisor, gen_super()}, {worker, gen_worker()}]).

%% @doc a supervisor description. @end
gen_super() -> {atom(), ex_super, {}}.

%% @doc a worker description. @end
gen_worker() -> {atom(), ex_worker, gen_service_status()}.

%% @doc potential statuses of the service reported by uffda. @end %%
gen_service_status() ->
    union([not_registered, registered, starting_up, restarting, slow_start, slow_restart, crashed, down, up]).

%% @doc Available real world events for the service to go through. @end %%
gen_rwe() ->
    union([go_up, go_down]).
