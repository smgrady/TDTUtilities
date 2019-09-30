function setElectrodeLocationFromAnimal(originalAnimal,targetAnimal)
% Copies electrode map and description from one animal to another in the
% database, because most maps are standardized and replicated.
% test example
% originalAnimal = 'LFP16';
% targetAnimal = 'LFP17';
dbConn = dbConnect(); %handle this better?  close db at end?
try
    animalIDOriginal = fetchAdjust(dbConn,['SELECT animalID FROM animals WHERE animalName = ''' originalAnimal '''']);
    animalIDOriginal = animalIDOriginal{1};
    probeRequestText = fetchAdjust(dbConn,['SELECT * FROM probe WHERE animalID='  num2str(animalIDOriginal) ]);
catch
    error('First animal not found');
end
try
    animalIDTarget = fetchAdjust(dbConn,['SELECT animalID FROM animals WHERE animalName = ''' targetAnimal '''']);
    animalIDTarget = animalIDTarget{1};
    % add a check here to make sure there isn't already a probe for this animal
    if ~isempty(fetchAdjust(dbConn,['SELECT * FROM probe WHERE animalID='  num2str(animalIDTarget) ]))
        error('probe information already exists')
    end
catch why
    keyboard
end

addNotebookEntry = ['INSERT INTO probe (probeName, channelNames, probeTarget,'...
    'animalID, probeType) VALUES (''' targetAnimal ' probe' ''',''' probeRequestText{3} ''','''...
    probeRequestText{4} ''',' num2str(animalIDTarget) ',''' probeRequestText{6} ''')'];
exec(dbConn,addNotebookEntry);

close(dbConn);