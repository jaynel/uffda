-module(sr_client).

-export([register_me/1, get_state/1, go_up/1, go_down/1, reset/1, wait/1]).
-type service() :: atom().

-spec register_me(service()) -> {ok, pid()} | {error, term()}.
register_me(Service) ->
    supervisor:start_child(service_registry_sup, [Service, self()]).

-spec get_state(service()) -> atom().
get_state(Service) ->
    FSM = service_fsm:fsm_name_from_service(Service),
    gen_fsm:sync_send_all_state_event(FSM, get_state).

-type response() :: ok | {error, term()}.

-spec go_up(service()) -> response().
go_up(Service) ->
    FSM = service_fsm:fsm_name_from_service(Service),
    gen_fsm:send_event(FSM, go_up).

-spec go_down(service()) -> response().
go_down(Service) ->
    FSM = service_fsm:fsm_name_from_service(Service),
    gen_fsm:send_event(FSM, go_down).

-spec reset(service()) -> response().
reset(Service) ->
    FSM = service_fsm:fsm_name_from_service(Service),
    gen_fsm:send_event(FSM, reset).

-spec wait(service()) -> response().
wait(Service) ->
    FSM = service_fsm:fsm_name_from_service(Service),
    gen_fsm:send_event(FSM, wait).
