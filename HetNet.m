function params = HetNet(params)
% heterogeneous scenario consisting of various base station and user types
% Macro, pico, and femto base stations and pedestrian and car users are
% placed in the simulation region. The femto cells are favored for cell
% association and NOMA is used for transmission. The macroscopic fading
% models are set individually for each link type. Indoor and LOS decisions
% for links are set per user type and PDP channel models are used for
% pedestrian and vehicular users and an AWGN channel is assumed for users
% in clusters around femto base stations. A weighted round robin scheduler
% favors vehicular users for scheduling.
%
% initial author: Fjolla Ademaj
% modifications author: Gabriel A. Queiroz
%
% see also launcherFiles.launcherHetNet

%% General Configuration
% time config
params.time.slotsPerChunk = 10;
params.time.feedbackDelay = 1; % small feedback delay

% set NOMA parameters
params.noma.mustIdx                 = parameters.setting.MUSTIdx.Idx01;
params.noma.interferenceFactorSic	= 0; % no error propagation
params.noma.deltaPairdB             = 7;
% perform NOMA transmssion even if far user CQI is low - this will increase the number of failed transmissions
params.noma.abortLowCqi             = true;

% define the region of interest
params.regionOfInterest.xSpan = 300;
params.regionOfInterest.ySpan = 300;

% set carrier frequency and bandwidth
params.carrierDL.centerFrequencyGHz             = 2; % in GHz
params.transmissionParameters.DL.bandwidthHz    = 10e6; % in Hz

% associate users to cell with strongest receive power - favor femto cell association
params.cellAssociationStrategy                      = parameters.setting.CellAssociationStrategy.maxReceivePower;
params.pathlossModelContainer.cellAssociationBiasdB = [0, 0, 5];

% weighted round robin scheduler - scheduling weights are set at the user
params.schedulerParameters.type = parameters.setting.SchedulerType.roundRobin;

% additional object that should be saved into simulation results
params.save.losMapUEAnt     = true;
params.save.isIndoor        = true;

%% pathloss model container
indoor	= parameters.setting.Indoor.indoor;
outdoor	= parameters.setting.Indoor.outdoor;
LOS     = parameters.setting.Los.LOS;
NLOS	= parameters.setting.Los.NLOS;

% macro base station models
macro = parameters.setting.BaseStationType.macro;
params.pathlossModelContainer.modelMap{macro,	indoor,     LOS}        = parameters.pathlossParameters.UrbanMacro5G;
params.pathlossModelContainer.modelMap{macro,	indoor,     LOS}.isLos  = true;
params.pathlossModelContainer.modelMap{macro,	indoor,     NLOS}       = parameters.pathlossParameters.UrbanMacro5G;
params.pathlossModelContainer.modelMap{macro,	indoor,     NLOS}.isLos = false;
params.pathlossModelContainer.modelMap{macro,	outdoor,	LOS}        = parameters.pathlossParameters.UrbanMacro5G;
params.pathlossModelContainer.modelMap{macro,	outdoor,	LOS}.isLos  = true;
params.pathlossModelContainer.modelMap{macro,	outdoor,	NLOS}       = parameters.pathlossParameters.UrbanMacro5G;
params.pathlossModelContainer.modelMap{macro,	outdoor,	NLOS}.isLos = false;
% pico base station models
pico = parameters.setting.BaseStationType.pico;
params.pathlossModelContainer.modelMap{pico,	indoor,     LOS}    = parameters.pathlossParameters.FreeSpace;
params.pathlossModelContainer.modelMap{pico,	indoor,     NLOS}   = parameters.pathlossParameters.FreeSpace;
params.pathlossModelContainer.modelMap{pico,	outdoor,	LOS}    = parameters.pathlossParameters.FreeSpace;
params.pathlossModelContainer.modelMap{pico,	outdoor,	NLOS}   = parameters.pathlossParameters.FreeSpace;
% femto base station models
femto = parameters.setting.BaseStationType.femto;
params.pathlossModelContainer.modelMap{femto,	indoor,     LOS}    = parameters.pathlossParameters.Indoor;
params.pathlossModelContainer.modelMap{femto,   indoor,     NLOS}   = parameters.pathlossParameters.Indoor;
params.pathlossModelContainer.modelMap{femto,	outdoor,    LOS}    = parameters.pathlossParameters.StreetCanyonLOS;
params.pathlossModelContainer.modelMap{femto,	outdoor,	NLOS}   = parameters.pathlossParameters.StreetCanyonNLOS;

%% Configuration of the Network Elements
% macro base stations
macroBS = parameters.basestation.HexGrid;
macroBS.interBSdistance         = 120;
macroBS.antenna                 = parameters.basestation.antennas.Omnidirectional;
macroBS.antenna.nTX             = 1; %4
macroBS.antenna.transmitPower   = 40;
macroBS.antenna.baseStationType = parameters.setting.BaseStationType.macro;
macroBS.antenna.height          = 35;
params.baseStationParameters('macro') = macroBS;

% pico base stations along a straight street
posPico = [-145, -75,  0, 75, 145;...
    24,  36, 24, 36,  24];
streetPicoBS = parameters.basestation.PredefinedPositions;
streetPicoBS.positions                  = posPico;
streetPicoBS.antenna                    = parameters.basestation.antennas.Omnidirectional;
streetPicoBS.antenna.nTX                = 1;
streetPicoBS.antenna.height             = 5;
streetPicoBS.antenna.baseStationType    = parameters.setting.BaseStationType.pico;
streetPicoBS.antenna.transmitPower      = 20;
params.baseStationParameters('pico') = streetPicoBS;

% User configuration
%IoT
%Pedestrian (HTTP, VoIP, Video, Gaming, FullBuffer)
%Vehicular

% IoT: clustered users with femtocells at cluster's center
% TraficModel = FullBuffer


clusteredUser = parameters.user.UniformCluster;
clusteredUser.density           = 250e-6; % density of clusters
clusteredUser.clusterRadius     = 5;
clusteredUser.clusterDensity    = 5.8e-2; % density of users in a cluster
clusteredUser.nRX               = 1;
clusteredUser.speed             = 0; % static user
clusteredUser.movement          = parameters.user.movement.Static;
clusteredUser.schedulingWeight  = 1; % do not favor this user type
clusteredUser.indoorDecision    = parameters.indoorDecision.Static(parameters.setting.Indoor.indoor);
clusteredUser.losDecision       = parameters.losDecision.StreetCanyon;
clusteredUser.channelModel      = parameters.setting.ChannelModel.Rayleigh;
clusteredUser.withFemto         = true;
clusteredUser.femtoParameters.antenna                   = parameters.basestation.antennas.Omnidirectional;
clusteredUser.femtoParameters.antenna.nTX               = 1;
clusteredUser.femtoParameters.antenna.height            = 1.5;
clusteredUser.femtoParameters.antenna.transmitPower     = 1;
clusteredUser.femtoParameters.antenna.baseStationType   = parameters.setting.BaseStationType.femto;

clusteredUser.trafficModel.type       = parameters.setting.TrafficModelType.FullBuffer;
%clusteredUser.trafficModel.size      = 94;
%clusteredUser.trafficModel.numSlots  = 2;

params.userParameters('clusterUser') = clusteredUser;


% Pedestrians - mixed traffic models

% 1 FullBuffer
poissonPedestriansFullBuffer = parameters.user.Poisson2D;
poissonPedestriansFullBuffer.nElements            = 100; % number of users placed
poissonPedestriansFullBuffer.nRX                  = 1;
poissonPedestriansFullBuffer.speed                = 0; % static user
poissonPedestriansFullBuffer.movement             = parameters.user.movement.Static;
poissonPedestriansFullBuffer.schedulingWeight     = 1; % do not favor this user type
poissonPedestriansFullBuffer.indoorDecision       = parameters.indoorDecision.Random(0.5);
poissonPedestriansFullBuffer.losDecision          = parameters.losDecision.UrbanMacro5G;
poissonPedestriansFullBuffer.channelModel         = parameters.setting.ChannelModel.PedA;
poissonPedestriansFullBuffer.trafficModel.type    = parameters.setting.TrafficModelType.FullBuffer;
params.userParameters('poissonUserPedestrianFullBuffer') = poissonPedestriansFullBuffer;


% 2 HTTP
poissonPedestriansHTTP = parameters.user.Poisson2D;
poissonPedestriansHTTP.nElements            = 100; % number of users placed
poissonPedestriansHTTP.nRX                  = 1;
poissonPedestriansHTTP.speed                = 0; % static user
poissonPedestriansHTTP.movement             = parameters.user.movement.Static;
poissonPedestriansHTTP.schedulingWeight     = 1; % do not favor this user type
poissonPedestriansHTTP.indoorDecision       = parameters.indoorDecision.Random(0.5);
poissonPedestriansHTTP.losDecision          = parameters.losDecision.UrbanMacro5G;
poissonPedestriansHTTP.channelModel         = parameters.setting.ChannelModel.PedA;
poissonPedestriansHTTP.trafficModel.type    = parameters.setting.TrafficModelType.HTTP;
params.userParameters('poissonUserPedestrianHTTP') = poissonPedestriansHTTP;


% 3 Video
poissonPedestriansVideo = parameters.user.Poisson2D;
poissonPedestriansVideo.nElements            = 100; % number of users placed
poissonPedestriansVideo.nRX                  = 1;
poissonPedestriansVideo.speed                = 0; % static user
poissonPedestriansVideo.movement             = parameters.user.movement.Static;
poissonPedestriansVideo.schedulingWeight     = 1; % do not favor this user type
poissonPedestriansVideo.indoorDecision       = parameters.indoorDecision.Random(0.5);
poissonPedestriansVideo.losDecision          = parameters.losDecision.UrbanMacro5G;
poissonPedestriansVideo.channelModel         = parameters.setting.ChannelModel.PedA;
poissonPedestriansVideo.trafficModel.type       = parameters.setting.TrafficModelType.Video;
%poissonPedestriansVideo.trafficModel.delayConstraint   = 100; 
params.userParameters('poissonUserPedestrianVideo') = poissonPedestriansVideo;


% 4 VoIP
poissonPedestriansVoIP = parameters.user.Poisson2D;
poissonPedestriansVoIP.nElements            = 100; % number of users placed
poissonPedestriansVoIP.nRX                  = 1;
poissonPedestriansVoIP.speed                = 0; % static user
poissonPedestriansVoIP.movement             = parameters.user.movement.Static;
poissonPedestriansVoIP.schedulingWeight     = 1; % do not favor this user type
poissonPedestriansVoIP.indoorDecision       = parameters.indoorDecision.Random(0.5);
poissonPedestriansVoIP.losDecision          = parameters.losDecision.UrbanMacro5G;
poissonPedestriansVoIP.channelModel         = parameters.setting.ChannelModel.PedA;
poissonPedestriansVoIP.trafficModel.type    = parameters.setting.TrafficModelType.VoIP;
%poissonPedestriansVoIP.trafficModel.delayConstraint   = 40;
params.userParameters('poissonUserPedestrianVoIP') = poissonPedestriansVoIP;


% 5 Gaming
poissonPedestriansGaming = parameters.user.Poisson2D;
poissonPedestriansGaming.nElements            = 100; % number of users placed
poissonPedestriansGaming.nRX                  = 1;
poissonPedestriansGaming.speed                = 0; % static user
poissonPedestriansGaming.movement             = parameters.user.movement.Static;
poissonPedestriansGaming.schedulingWeight     = 1; % do not favor this user type
poissonPedestriansGaming.indoorDecision       = parameters.indoorDecision.Random(0.5);
poissonPedestriansGaming.losDecision          = parameters.losDecision.UrbanMacro5G;
poissonPedestriansGaming.channelModel         = parameters.setting.ChannelModel.PedA;
poissonPedestriansGaming.trafficModel.type              = parameters.setting.TrafficModelType.Gaming;
%poissonPedestriansGaming.trafficModel.delayConstraint   = 60; 
params.userParameters('poissonUserPedestrianGaming') = poissonPedestriansGaming;


% Vehicular

% PPP 
poissonCars                     = parameters.user.Poisson2D;
poissonCars.nElements           = 50;
poissonCars.nRX                 = 1; %2
poissonCars.speed               = 50/3.6;
poissonCars.movement            = parameters.user.movement.RandomDirection;
poissonCars.schedulingWeight    = 10; % assign 10 resource blocks when scheduled
poissonCars.indoorDecision      = parameters.indoorDecision.Static(parameters.setting.Indoor.outdoor);
poissonCars.losDecision         = parameters.losDecision.UrbanMacro5G;
poissonCars.channelModel        = parameters.setting.ChannelModel.VehB;

poissonCars.trafficModel.type       = parameters.setting.TrafficModelType.FullBuffer;


params.userParameters('poissonUserCar') = poissonCars;


% PicoBS - vehicular users distributed in streets and served by PicoBS
width_y     = 8;
width_x     = 150;
nUser       = 50;
xRandom     =      width_x * rand(1, nUser) - width_x / 2;
yRandom     = 30 + width_y * rand(1, nUser) - width_y / 2;
posUser3    = [xRandom; yRandom; 1.5*ones(1,nUser)];
streetCars = parameters.user.PredefinedPositions;
streetCars.positions            = posUser3;
streetCars.nRX                  = 1; %2
streetCars.speed                = 100/3.6;
streetCars.movement             = parameters.user.movement.RandomDirection;
streetCars.schedulingWeight     = 10; % assign 10 resource blocks when scheduled
streetCars.indoorDecision       = parameters.indoorDecision.Static(parameters.setting.Indoor.outdoor);
streetCars.losDecision          = parameters.losDecision.Static;
streetCars.losDecision.isLos    = true;
streetCars.channelModel         = parameters.setting.ChannelModel.VehA;

streetCars.trafficModel.type       = parameters.setting.TrafficModelType.FullBuffer;


params.userParameters('vehicle') = streetCars;

end