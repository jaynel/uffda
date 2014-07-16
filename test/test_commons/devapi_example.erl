-module(devapi_example).
-behaviour(tc_proper_model).

-export([
         get_all_test_model_ids/0,
         generate_proper_model/2,
         deduce_proper_expected_status/1,

         vivify_proper_scenario/1,
         translate_proper_scenario_dsl/1,
         translate_proper_scenario_events/1,
         generate_proper_observation/2,
         passed_proper_test_case/3
        ]).

-include("tc_proper_model.hrl").

-spec get_all_test_model_ids() -> [{Model_Id :: tc_proper_model_id(), Source :: tc_proper_model_source()}].
get_all_test_model_ids() ->
    [{devapi_example, {file, "devapi_example"}}].

-spec generate_proper_model(Model_Id :: tc_proper_model_id(), Source :: tc_proper_model_source()) -> tc_proper_model().
generate_proper_model(Id, {file, Filename} = Source) ->
    {ok, Scenarios} = file:consult(Filename),
    #tc_proper_model{id=Id, source=Source, behaviour=?MODULE, scenarios=Scenarios}.

-spec deduce_proper_expected_status(Scenario_Instance :: tc_proper_scenario()) -> Expected_Status :: term().
deduce_proper_expected_status(#tc_proper_scenario{} = Scenario) ->
    #tc_proper_scenario{instance=Inst, scenario_desc=Desc, initial_status=Init_Status, events=Events} = Scenario,
    Expected_Status = try   deduce(Desc, Init_Status, Events)
                      catch Error:Type -> error_logger:error_msg("Caught ~p error in ~p:deduce/3 ~p",
                                                                 [{Error, Type}, ?MODULE, erlang:get_stacktrace()]),
                                          failed
                      end,
    #tc_proper_test_case{scenario=Scenario, expected_status=Expected_Status}.

-spec vivify_proper_scenario(Scenario :: tc_proper_scenario()) -> tc_proper_scenario_live_ref().
vivify_proper_scenario(#tc_proper_scenario{} = Scenario) ->
    devapi_tester.

-spec translate_proper_scenario_dsl(tc_proper_scenario_dsl_desc()) -> tc_proper_scenario_live_desc().
translate_proper_scenario_dsl(Dsl_Scenario) ->
    Dsl_Scenario.

-spec translate_proper_scenario_events(tc_proper_scenario_dsl_events()) -> tc_proper_scenario_live_events().
translate_proper_scenario_events(Dsl_Events) ->
    Dsl_Events.

-spec generate_proper_observation(tc_proper_scenario_live_ref(), tc_proper_test_case()) -> term().
generate_proper_observation(_Live_Model_Ref, #tc_proper_test_case{} = _Test_Case_Instance) ->
    success.

-spec passed_proper_test_case(Case_Number     :: pos_integer(),
                              Expected_Status :: tc_proper_scenario_dsl_status(),
                              Observed_Status :: tc_proper_scenario_live_status()) -> boolean().
passed_proper_test_case(_Case_Number, Expected_Status, Observed_Status) ->
    true.


%%--------------------------------
%% Support functions
%%--------------------------------
deduce(_Desc, _Init_Status, _Events) ->
    expected.
