-module(uffda).
-behavior(application).

-export([start/0, stop/0]).
-export([start/2, stop/1]).

%%-------------------------------------------------------------------
%% ADMIN API
%%-------------------------------------------------------------------
%% @doc Starts the application
-spec start() -> ok | {error, {already_started, ?MODULE}}.
start() -> application:start(?MODULE).

%% @doc Stops the application
-spec stop() -> ok.
stop() -> application:stop(?MODULE).

%%-------------------------------------------------------------------
%% BEHAVIOUR CALLBACKS
%%-------------------------------------------------------------------
%% @private
-spec start(any(), any()) -> {ok, pid()}.
start(_StartType, _StartArgs) -> 
    service_registry_sup:start_link().

%% @private
-spec stop(any()) -> no_return().
stop(_State) ->
	case application:get_env(?MODULE, halt_on_stop) of
		{ok, false} -> ok;
		_ ->
    		_ = lager:critical("Application ~p stopped. Halting!", [?MODULE]),
    		erlang:halt(1)
	end.
