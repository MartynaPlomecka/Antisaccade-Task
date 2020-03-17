


clear all

system = 1 %0 (1 = MAC, 0 = Windows)

if system == 1
 
cd('/Volumes/methlab/Neurometric/Antisaccades/ALL/eeglab14_1_2b/')
addpath('/Volumes/methlab/Neurometric/Antisaccades/ALL/')
addpath('/Volumes/methlab/Neurometric/Antisaccades/ALL/FastICA_25')
addpath('/Volumes/methlab/Neurometric/Antisaccades/ALL/UNFOLD/unfold')

eeglab;
close
table_old =readtable("/Volumes/methlab/Neurometric/Antisaccades/ALL/old.xlsx");
table_young =readtable("/Volumes/methlab/Neurometric/Antisaccades/ALL/young.xlsx");
oldIDsA = table_old{3:end,1};
oldIDsB= table_old{3:end,2};
all_oldIDs = [oldIDsA; oldIDsB];
youngIDsA = table_young{3:end,1};
youngIDsB= table_young{3:end,2};
all_youngIDs = [youngIDsA; youngIDsB];
 
raw = '/Volumes/methlab/Neurometric/Antisaccades/main_analysis/EEG' % path to preprocessed eeg files
etfolder='/Volumes/methlab/Neurometric/Antisaccades/main_analysis/ET'; %et files
 
 
%WINDOWS
elseif system == 0 % Windows
cd('W:\Neurometric\Antisaccades\ALL\eeglab14_1_2b')
addpath('W:\Neurometric\Antisaccades\ALL\')
addpath('W:\Neurometric\Antisaccades\ALL\FastICA_25')
addpath('W:\Neurometric\Antisaccades\ALL\UNFOLD')
addpath('W:\Neurometric\Antisaccades\ALL\UNFOLD\unfold')

eeglab;
close
addpath('Tools') %
table_old = readtable("W:\Neurometric\Antisaccades\main_analysis\Resources\old.xlsx");
table_young =readtable("W:\Neurometric\Antisaccades\main_analysis\Resources\young.xlsx");
oldIDsA = table_old{3:end,1};
oldIDsB= table_old{3:end,2};
all_oldIDs = [oldIDsA; oldIDsB];
youngIDsA = table_young{3:end,1};
youngIDsB= table_young{3:end,2};
all_youngIDs = [youngIDsA; youngIDsB];
 
raw= 'W:\Neurometric\Antisaccades\main_analysis\EEG'; % path to preprocessed eeg files
etfolder='W:\Neurometric\Antisaccades\main_analysis\ET'; %MO
 
end



%%
 
d=dir(raw) %what folders are in there (each folder = one subject)
 
d(1:3)=[] % get rid of the . and .. folders as well as .DS_Store on mac
 
 
OLD_OR_YOUNG = {'old', 'yng'};


all_subjects ={};
old_subjects = {};
young_subjects = {};


AllEEG=[];

%% 
for i=1:4 %length(d) %loop over all subjects
    if d(i).isdir
        subjectfolder=dir([d(i).folder filesep d(i).name  ]);
        
        deleteindex=[];
        for ii=1:length(subjectfolder)
            if not(endsWith(subjectfolder(ii).name, '_EEG.mat')) || startsWith(subjectfolder(ii).name,'bip') || startsWith(subjectfolder(ii).name,'red')
                deleteindex(end+1)=ii;
            end
        end
        
        subjectfolder(deleteindex)=[];
        FullEEG=[];

        %old or young
        id=d(i).name ;
        clear young old
        young=    any(contains(all_youngIDs,id));
        old =     any(contains(all_oldIDs,id));
        
        
        
        names ={};
        for kkk=1:length(subjectfolder)
        names{kkk,1} =    subjectfolder(kkk).name;
        end
           
        
        for ii=1:length(subjectfolder)
           clear ind_t ind
            for kk = 1:length(subjectfolder)
                ind(kk) = ~isempty(strfind(names{kk},['AS',num2str(ii)]));
            end
            ind_t = find(ind);
            if isempty(ind_t)
                continue;
            end

            load ([subjectfolder(ind_t).folder filesep subjectfolder(ind_t).name]) % gets loaded as EEG
          %  fileindex=subjectfolder(ii).name(end-8) %here you need to find the index from thefile (end-someting) indexing
            etfile=  [etfolder filesep d(i).name filesep d(i).name '_AS' num2str(ii) '_ET.mat'] %define string of the complete path to the matching ET file.
             
            
            EEG = pop_eegfiltnew(EEG,[],30);%low pass filter 30Hz

            EEG = pop_reref(EEG,[]) % reref
            %EEG = pop_reref(EEG,[47 83])%in case of mastoids

            
            %merge ET into EEG
            ev1=94 %first trigger of eeg and ET file
            ev2=50 % end trigger in eeg and ET file
            EEG=pop_importeyetracker(EEG, etfile,[ev1 ev2], [1:4], {'TIME' 'L_GAZE_X' 'L_GAZE_Y' 'L_AREA'},1,1,0,0,4);
           
            %% change triggers here
            
       % countblocks = 0;
        previous = '';
        rmEventsIx = strcmp('L_fixation',{EEG.event.type}) | (strcmp('L_saccade',{EEG.event.type})&[EEG.event.sac_amplitude]<1.5) ;
        rmEv =  EEG.event(rmEventsIx);
        EEG.event(rmEventsIx) = [];
        
        for e = 1:length(EEG.event)
          
           if ~isempty(strfind(subjectfolder(ind_t).name,'AS2')) || ~isempty(strfind(subjectfolder(ind_t).name,'AS3')) || ~isempty(strfind(subjectfolder(ind_t).name,'AS4')) 
           % if countblocks == 2 || countblocks == 3 || countblocks == 4 % antisaccade blocks
                if strcmp(EEG.event(e).type,'10  ') % change 10 to 12 for AS
                    EEG.event(e).type = '12  ';
                elseif strcmp(EEG.event(e).type,'11  ')
                    EEG.event(e).type = '13  '; % change 11 to 13 for AS
               
                end
                if strcmp(EEG.event(e).type,'40  ') 
                    EEG.event(e).type = '41  ';
                end
            end

EEG.event(1).dir = []; %left or right
EEG.event(1).cond = [];%pro or anti
EEG.event(1).age = []; %old or young

%young == 1 -> 'young'
%young == 0 -> 'old'

if young == 0
  age='old';
else
  age='yng';
end
            if strcmp(EEG.event(e).type, 'L_saccade') 
                EEG.event(e).age = age;
                if strcmp(previous, '10  ')
                    EEG.event(e).type = 'saccade'
                    EEG.event(e).cond = 'pro';
                    EEG.event(e).dir = 'left';
                    %pro left
                 elseif strcmp(previous, '11  ')
                    EEG.event(e).type = 'saccade'
                    EEG.event(e).cond = 'pro';
                    EEG.event(e).dir = 'right';   
                 elseif strcmp(previous, '12  ')
                    EEG.event(e).type = 'saccade'
                    EEG.event(e).cond = 'anti';
                    EEG.event(e).dir = 'left';
                 elseif strcmp(previous, '13  ')
                    EEG.event(e).type = 'saccade'
                    EEG.event(e).cond = 'anti';
                    EEG.event(e).dir = 'right';
                end
            end
           
            
            if ~strcmp(EEG.event(e).type, 'L_fixation') ...
                    && ~strcmp(EEG.event(e).type, 'L_blink')
                previous = EEG.event(e).type;
            end
        end
        
        rmEv(1).cond = []; rmEv(1).dir = []; rmEv(1).age = [];
        EEG.event((end+1):(end+length(rmEv))) = rmEv;
        EEG = eeg_checkset(EEG,'eventconsistency');
      
            if isempty(FullEEG)
                FullEEG=EEG;
            else
                FullEEG=pop_mergeset(FullEEG,EEG);
            end
        end

        if isempty(FullEEG)
            continue
        end
        
            
        
      
        
        all_subjects{end+1,1} =id;
        if young == 0
        old_subjects{end+1,1} = id;
        elseif young == 1
        young_subjects{end+1,1} = id;  
        end
        
        
        %young = 1, old =  0
        all_ages(i) =    young;
        all_eeg{i} = FullEEG;
       
        
        %one huge structure, used for unfold
            if isempty(AllEEG)
                AllEEG=FullEEG;
            else
                AllEEG=pop_mergeset(AllEEG,FullEEG);
            end

        
      
    end
end


%% unfold part

AllEEG_noeye = AllEEG;
AllEEG_noeye.chanlocs = AllEEG.chanlocs(1:105);
AllEEG_noeye.data = AllEEG.data(1:105, :);
AllEEG_noeye.nbchan = 105;
        

%here Plotting Single-Trial ERPimages starts:
init_unfold

cfgDesign = [];
EEG = AllEEG_noeye;

EEG.event(1).dir = '';
EEG.event(1).cond = '';
for e =  1:length(EEG.event)
      ev = EEG.event(e);
    if ev.type == "10  " || ev.type == "11  " ||ev.type == "12  " || ev.type =="13  "
        ev.type = 'stimulus_onset';
    end
     EEG.event(e)  = ev;
end

%EEGorg = EEG;

cfgDesign.eventtypes = {'saccade',...
    'stimulus_onset', 'L_blink'};
cfgDesign.formula =  {'y ~ 1+cat(cond) + cat(dir) +  cat(age)', 'y ~ 1','y ~ 1'};
EEG = uf_designmat(EEG,cfgDesign);


cfgTimeexpand = [];
cfgTimeexpand.timelimits = [-0.6000 1];
EEG = uf_timeexpandDesignmat(EEG,cfgTimeexpand);

EEG= uf_glmfit(EEG);

%After fitting the EEG, we can visualize the ERPimages
uf_erpimage(EEG,'channel',1)


%% CFG-Trick

cfg = []

cfg.channel = 1
cfg.figure = 1

cfg.caxis = [-5,5]

cfg.alignto = {'stimulus_onset'} %had to be cell array,

cfg = [fieldnames(cfg),struct2cell(cfg)].';
cfg(:)

%% Raw ERPimage
% We can also look at the raw ERPimage. 
% This is the same as running eeg_erpimage on your typical epoched data. 
% compared to the overlap-corrected model-estimate, we have much more noise included here.

uf_erpimage(EEG,'type','raw',cfg{:})

%% Sorting trials by condition
%sorting trials by condition, for instance here by cond type (pro or anti).
uf_erpimage(EEG,'type','raw','sort_by','cond',cfg{:})
uf_erpimage(EEG,'type','modelled','sort_by','cond',cfg{:})

%% Sorting trials by event
%Let's sort by the next trial onset. For this we have to specify sort_time to sort by something larger than 0.
uf_erpimage(EEG,'type','raw','sort_time',[eps 1.5],'sort_alignto',{'stimulus_onset'},cfg{:})

