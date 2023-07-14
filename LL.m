function [Bid_res,Bpriori_res,Batch_res,nExpectedReloc,actions] = LL_new(Bid,Bpriori,Batch,k)%,oprs)
oprs='';
[Bid_new,Bpriori_new,Batch_new,oprs_new] = AutoRetrieval(Bid,Bpriori,Batch,k,oprs);

if Batch_new(k,1)==0
    Bid_res=Bid_new;
    Bpriori_res=Bpriori_new;
    Batch_res = Batch_new;
    nExpectedReloc=0;
    actions = oprs_new;
    return
end
%% We initialize the size of the configuration and maximum time window
[T,S] = size(Bid_new);

%% We compute the stack and tier (1 being the lowest) of the target container
target = Batch_new(k,2:end);
targetSeq = GenerateSequences(target,Bid_new);

%% The vector of minimums (0 for full columns and the target column; Z+1 for
% empty columns, where Z is the maximum time window)
[rows,~]=size(target);%size(targetSeq);
minCost=999;

for i=1:rows %%����ÿ����ȡ���е�����ѡλ
    curB=Bid_new;
    curPriori=Bpriori_new;
    curBatch = Batch_new; 
    curSeq = target(i,:);
    curCost=0;
    curOprs = oprs_new;
    
    curSeqAvailable = true;
    %����һЩ���Ʊ���
    minVector=zeros(1,S);
    minVector=minPriori(curPriori,0);
    min2Vector=zeros(1,S);
    min2Vector=minPrioriExceptTopmost(curPriori,0);
    
    % ����ǰĿ��������ȼ�����Ϊ0
    for j=1:length(curSeq)
        if curSeq(j)==0
            continue;
        end
        [row,col]=find(curB==curSeq(j));
        if isempty(row) || length(row)>1
            throw(MException('MATLAB:customerError','current target container not existing or existing more than one items'));
        end
        curPriori(row,col)=0;
    end
    [topIds, topPrioris] = Tops(curB, curPriori);
    % The height vector
    height = sum(curB~=0);

    % �Ե�ǰ���ε�Ŀ�������Ϊ�谭��ѡλ
    for j=1:length(curSeq)
        if curSeq(j)==0
            continue;
        end
        [row,col]=find(curB==curSeq(j));
        if isempty(row)
            continue;
        end
                
        while T-height(col)+1<row % ��ǰλ��ջ���Ĳ���Ŀ���䣬��Ҫ�Ƴ��谭��
            b=curB(T-height(col)+1,col);
            p=curPriori(T-height(col)+1,col);

            [bestStack,error] = FindBestPlacement(b,curB,curPriori);
            if bestStack~=0 %���������λ
                if isempty(curOprs)
                    curOprs = strcat('<',int2str(b),',',int2str(col),',',int2str(bestStack),'>');
                else
                    curOprs = strcat(curOprs,';<',int2str(b),',',int2str(col),',',int2str(bestStack),'>');
                end

                curB(T-height(bestStack),bestStack)=b;
                curPriori(T-height(bestStack),bestStack)=p;
                
                curB(T-height(col)+1,col)=0;
                curPriori(T-height(col)+1,col)=-1;
                    
                height = sum(curB~=0);
                
                if error==0
                    m=sum(curPriori(:,bestStack)==p);
                    curCost=curCost+1-1/m;
                elseif error<0
                    curCost=curCost+1;
                end
            else %�����������λ����ζ�Ŵ�˳�򲻿���
                disp(strcat('Round: ',num2str(k), 'Blocking: ',num2str(b), 'No available placement!'));
                curSeqAvailable = false;
                break;
            end
            curCost=curCost+1; %�ƶ���һ���谭��            
        end
        if T-height(col)+1<row
            curSeqAvailable=false;
            break; %�����н�
        else
            % ��ȡĿ����
            if isempty(curOprs)
                curOprs = strcat('<',int2str(curSeq(j)),',',int2str(col),',0>');
            else
                curOprs = strcat(curOprs,';<',int2str(curSeq(j)),',',int2str(col),',0>');
            end
            curB(row,col)=0;
            curPriori(row,col)=-1;
            height = sum(curB~=0);
        end
    end
    if ~curSeqAvailable
        disp('No available placement!');
    else
        if curCost<minCost
            minCost=curCost;
            actions=curOprs;
            Bid_res = curB;
            Bpriori_res = curPriori;
            Batch_res = curBatch;
        end
    end
end
nExpectedReloc = minCost;

%     
%         
%         %��ȡĿ������谭�伯��
%         blockings = curB(T-height(col)+1:row-1,col);
%         if ~isempty(blockings)
%             for y=1:length(blockings)                
%                 b = blockings(y);
%                 if b==0
%                     continue;
%                 end                
%                 % ���¼���ջ�Ĳ��
% %                 height = sum(curB~=0);
%                 
%                 l = T-height(col)+1;  %[l,col]=find(curB==b);
%                 p=curPriori(l,col);
%                 
%                 [bestStack,error] = FindBestPlacement(b,curB,curPriori);
%                 if bestStack~=0
%                     if isempty(curOprs)
%                         curOprs = strcat('<',int2str(b),',',int2str(col),',',int2str(bestStack),'>');
%                     else
%                         curOprs = strcat(curOprs,';<',int2str(b),',',int2str(col),',',int2str(bestStack),'>');
%                     end
% 
%                     curB(T-height(bestStack),bestStack)=b;
%                     curPriori(T-height(bestStack),bestStack)=p;
%                     curB(l,col)=0;
%                     curPriori(l,col)=-1;
%                     
%                     height(bestStack)=height(bestStack)+1;
%                     height(col)=height(col)-1;
%                     
%                     if error==0
%                         m=sum(curPriori(:,bestStack)==p);
%                         curCost=curCost+1-1/m;
%                     elseif error<0
%                         curCost=curCost+1;
%                     end
%                 else
%                     curSeqAvailable = false;
%                     break;
% %                     throw(strcat('Not found an available placement for blocking container ',num2str(b)));
%                 end
%                 curCost=curCost+1; %�ƶ���һ���谭��
%             end
%         end
%         if ~curSeqAvailable
%             break;
%         end
%         % ��ȡĿ����
% %         [row,col]=find(curB==curSeq(j));
%         if isempty(curOprs)
%             curOprs = strcat('<',int2str(curSeq(j)),',',int2str(col),',0>');
%         else
%             curOprs = strcat(curOprs,';<',int2str(curSeq(j)),',',int2str(col),',0>');
%         end
%         curB(row,col)=0;
%         curPriori(row,col)=-1;
%     end
%     if curCost<minCost
%         minCost=curCost;
%         actions=curOprs;
%         Bid_res = curB;
%         Bpriori_res = curPriori;
%         Batch_res = curBatch;
%     end
% end
% nExpectedReloc = minCost;
