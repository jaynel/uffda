-module(service_fsm).
-behavior(gen_fsm).

-export([init/1, handle_event/3, handle_sync_event/4,
		 handle_info/3, code_change/4, terminate/3]).

-export([start_link/2, fsm_name_from_service/1]).

%% States of a Service
-export(['STARTING_UP'/2,
         'UP'/2,
         'DOWN'/2]).

-type service() :: atom().

-spec fsm_name_from_service(service()) -> atom().
fsm_name_from_service(Service) ->
    Name = atom_to_list(Service),
    list_to_atom(Name ++ "_fsm").

-spec start_link(atom(), pid()) -> {ok, pid()}.
start_link(Service, ServicePid) ->
    ServFSM = fsm_name_from_service(Service),
    gen_fsm:start_link({local, ServFSM}, ?MODULE, [Service, ServicePid], []).


%%----------------------------------------------------
%% States of a Service
%%----------------------------------------------------

%% A Service is starting up
-spec 'STARTING_UP'(term(), term()) -> {next_state, atom(), term()} 
                                     | {stop, term(), term()}. 
'STARTING_UP'(go_up, StateData) -> {next_state, 'UP', StateData};
'STARTING_UP'(wait, StateData) -> {next_state, 'DOWN', StateData};
'STARTING_UP'(Event, StateData) ->
	lager:error("~p: unexpected event \"~p\", state was ~p", [?MODULE, Event, StateData]),
    {next_state, 'STARTING_UP', StateData}.

%% A Service is up and running
-spec 'UP'(term(), term()) -> {next_state, atom(), term()}
                            | {stop, term(), term()}.
'UP'(go_down, StateData) -> {next_state, 'DOWN', StateData};
'UP'(Event, StateData) ->
	lager:error("~p: unexpected event \"~p\", state was \"~p\" state data was \"~p\"",
        [?MODULE, Event, 'UP', StateData]),
	{next_state, 'UP', StateData}.

%% A Service is down
-spec 'DOWN'(term(), term()) -> {next_state, atom(), term()}
                              | {stop, term(), term()}.
'DOWN'(reset, StateData) -> {next_state, 'UP', StateData};
'DOWN'(Event, StateData) ->
    lager:error("~p: unexpected event \"~p\", state was \"~p\", state data was \"~p\"",
        [?MODULE, Event, 'DOWN', StateData]),
    {next_state, 'DOWN', StateData}.

%%---------------------------------------------------
%% gen_fsm API callbacks 
%%---------------------------------------------------

-spec init(term()) -> {ok, atom(), term()}.
init(Args) ->
 %%   [_Name, Pid] = Args,
 %%   monitor(process, Pid),
    {ok, 'STARTING_UP', Args}.

-spec handle_event(term(), atom(), term()) -> {next_state, atom(), term()}
                                              | {stop, atom(), term()}.
handle_event(Event, StateName, StateData) ->
    lager:error("~p: unexpected event \"~p\", state data was ~p",
        [?MODULE, Event, StateData]),
    {next_state, StateName, StateData}.

-spec handle_sync_event(term(), {pid(), term()}, atom(), term()) ->
    {next_state, atom(), term()} | {stop, term(), term()}.
handle_sync_event(get_state, _From, StateName, StateData) ->
    {reply, StateName, StateName, StateData};
handle_sync_event(Event, _From, StateName, StateData) ->
    lager:error("~p:unexpected event \"~p\", state data was ~p", [?MODULE, Event, StateData]),
    {reply, {error, unexpected_message}, StateName, StateData}.

-spec handle_info(term(), atom(), term()) -> {next_state, atom(), term()}
                                             | {stop, atom(), term()}.
handle_info(Info, StateName, StateData) ->
    lager:error("~p:unexpected info \"~p\", state data was ~p", [?MODULE, Info, StateData]),
    {next_state, StateName, StateData}.

-spec terminate(term(), atom(), term()) -> ok | {stop, unexpected_message, term()}.
terminate(normal, _, _) -> ok;
terminate(shutdown, _, _) -> ok;
terminate(Reason, _StateName, StateData) ->
    lager:error("~p:unexpected reason \"~p\", state data was ~p", [?MODULE, Reason, StateData]),
    ok.

-spec code_change(term(), atom(), term(), term()) -> {ok, atom(), term()}.
code_change(OldVsn, StateName, StateData, _Extra) ->
    lager:error("~p:unexpected version \"~p\", state data was ~p", [?MODULE, OldVsn, StateData]),
    {ok, StateName, StateData}.
