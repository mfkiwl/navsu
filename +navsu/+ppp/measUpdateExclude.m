function [H,delta_z,residsPost,K,predMeas,measMatRemoved,R,measIdRemoved,measId,innovStruc] =  ...
    measUpdateExclude(H,cov_propagated,R,predMeas,PARAMS,meas,measId,epoch)

% loop through and remove bad measurements, starting with the bad ones,
% until they are all clean

measMatRemoved = zeros(0,6);
measIdRemoved = [];

%% Innovation checks

% Save some informaiton about the innovations lol
innovStruc.innov = meas-predMeas;
innovStruc.measId = measId;
innovStruc.epochs = repmat(epoch,size(measId));
% Build residual exclusion factor vector
threshInnov = zeros(size(measId,1),1);
measTypeList = cat(1,measId.TypeID);
types = unique(measTypeList);

for idx = 1:length(types)
    if types(idx) == navsu.internal.MeasEnum.Wheels
        threshInnov(types(idx) == measTypeList) = 0.05+Inf;
    else
        threshInnov(types(idx) == measTypeList) = Inf;
    end
end

indsLargeInnov = find(abs(meas-predMeas) > threshInnov);

% remove from H,R,measMat,pred_meas
H(indsLargeInnov,:) = [];
R(indsLargeInnov,:) = [];
R(:,indsLargeInnov) = [];
predMeas(indsLargeInnov,:) = [];

meas(indsLargeInnov) = [];
measId(indsLargeInnov) = [];

%%


largeResids  = true;
mediumResids = true;

% Build residual exclusion factor vector
threshLarge = zeros(size(measId,1),1);
threshMedium = zeros(size(measId,1),1);
measTypeList = cat(1,measId.TypeID);
types = unique(measTypeList);

for idx = 1:length(types)
    if types(idx) == navsu.internal.MeasEnum.GNSS
        indsGnss = find(types(idx) == measTypeList);
        
        measSubtypes = cat(1,measId(indsGnss).subtype);
        indsCode = indsGnss(measSubtypes == navsu.internal.MeasEnum.Code);
        indsCarrier = indsGnss(measSubtypes == navsu.internal.MeasEnum.Carrier);
        indsDoppler = indsGnss(measSubtypes == navsu.internal.MeasEnum.Doppler);

        threshLarge(indsCode) = PARAMS.measUse.excludeThreshLarge.GNSS.Code;
        threshLarge(indsCarrier) = PARAMS.measUse.excludeThreshLarge.GNSS.Carrier;
        threshLarge(indsDoppler) = PARAMS.measUse.excludeThreshLarge.GNSS.Doppler;
        
        threshMedium(indsCode) = PARAMS.measUse.excludeThresh.GNSS.Code;
        threshMedium(indsCarrier) = PARAMS.measUse.excludeThresh.GNSS.Carrier;
        threshMedium(indsDoppler) = PARAMS.measUse.excludeThresh.GNSS.Doppler;
    else
        threshLarge(types(idx) == measTypeList) = PARAMS.measUse.excludeThreshLarge.(char(types(idx)));
        threshMedium(types(idx) == measTypeList) = PARAMS.measUse.excludeThresh.(char(types(idx)));
    end
end


idx = 1;
while largeResids || mediumResids
    % Keep iterating until there are no bad measurements
    
    % 7. Calculate Kalman gain using (3.21)
    K = (cov_propagated * H') /(H *cov_propagated * H' + R);
    
    % 8. Measurement innovations
    fullMeas = meas;
    delta_z  = fullMeas-predMeas;
    
    residsPost = delta_z-H*K*delta_z;
    
    % Set the thresholds- remove large errors first
    excludeThreshLarge = threshLarge;
    excludeThreshMedium = threshMedium;
%     
    indsLargeResids  = find(abs(residsPost)>excludeThreshLarge);
    indsMediumResids = find(abs(residsPost)>excludeThreshMedium);
    
    % Check where we are currently- are there large or small residuals?
    if isempty(indsLargeResids)
        largeResids = false;
    end
    
    if isempty(indsMediumResids)
        % If we have no residuals exceeding our smaller threshold, just move
        % forward with what we have- these are clean
        mediumResids = false;
    end
    
    % can only remove using EITHER large or small thresholds, not one then
    % the other
    if ~isempty(indsLargeResids)
        % Remove large residuals
        % save what we're removing
        
        measIdRemoved = [measIdRemoved; measId(indsLargeResids)];
        
        % remove from H,R,measMat,pred_meas
        H(indsLargeResids,:) = [];
        R(indsLargeResids,:) = [];
        R(:,indsLargeResids) = [];
        predMeas(indsLargeResids,:) = [];
        
        meas(indsLargeResids) = [];
        measId(indsLargeResids) = [];
        threshLarge(indsLargeResids) = [];
        threshMedium(indsLargeResids) = [];
        
        
    elseif ~isempty(indsMediumResids) && largeResids == false
        % Only if we have found that there are no large residuals can we
        % remove using the small threshold.
         
        % save what we're removing
        measIdRemoved = [measIdRemoved; measId(indsMediumResids)];
        
        % remove from H,R,measMat,pred_meas
        H(indsMediumResids,:) = [];
        R(indsMediumResids,:) = [];
        R(:,indsMediumResids) = [];
        predMeas(indsMediumResids,:) = [];
        
        meas(indsMediumResids) = [];
        measId(indsMediumResids) = [];
        
        threshLarge(indsMediumResids) = [];
        threshMedium(indsMediumResids) = [];
    end
    
    idx = idx+1;
    
    if idx > 20
        error('Measurement update is taking too long- please come check this out');
    end

end



end
