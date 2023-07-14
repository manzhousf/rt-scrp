function [Bid_res, Bpriori_res, Batch_res, nReloc, actions] = SPFH_new(Bid,Bpriori,Batch,k) %,oprs)
oprs = '';
[Bid_new,Bpriori_new,Batch_new,oprs_new] = AutoRetrieval(Bid,Bpriori,Batch,k,oprs);

if Batch_new(k,1)==0
    Bid_res=Bid_new;
    Bpriori_res=Bpriori_new;
    Batch_res=Batch_new;
    nReloc=0;
    actions = oprs_new;
    return
end

[T,S] = size(Bid_new);

%% We compute the stack and tier (1 being the lowest) of the target container
target = Batch_new(k,2:end);
targetSeq = GenerateSequences(target,Bid_new);

%% The vector of minimums (0 for full columns and the target column; Z+1 for
% empty columns, where Z is the maximum time window)
[rows,~]=size(targetSeq);
minCost=999;

for i=1:rows %%����ÿ����ȡ���е�����ѡλ
    curB=Bid_new;
    curPriori=Bpriori_new;
    curSeq = targetSeq(i,:);
    curBatch = Batch_new;
    curCost=0;
    curOprs = oprs_new;
    
    curSeqAvailable = true;
    
    
    % ����ǰĿ��������ȼ�����Ϊ0
    for j=1:length(curSeq)
        if curSeq(j)==0
            continue;
        end
        [row,col]=find(curB==curSeq(j));
        curPriori(row,col)=0;
    end
    
    % �Ե�ǰ���ε�Ŀ�������Ϊ�谭��ѡλ
    while ~isempty(curSeq)%for j=1:length(curSeq)
        %����һЩ���Ʊ���
        minVector=zeros(1,S);
        minVector=minPriori(curPriori,0);
        min2Vector=zeros(1,S);
        min2Vector=minPrioriExceptTopmost(curPriori,0);
        % The height vector
        height = sum(curB~=0);
        
        [row,col]=find(curB==curSeq(1));
       if isempty(row)
           curSeq(:,1)=[];
           continue;
       end
        while T-height(col)+1<row %ջ������Ŀ���䣬������Ҫ�Ƴ����谭��
            b=curB(T-height(col)+1,col);
            p=curPriori(T-height(col)+1,col);
            
%             col,curB,curPriori,height
            [bestStack,error] = FindBestPlacement(b,curB,curPriori);
            
            if bestStack==0
                disp(strcat('Round: ',num2str(k), 'Blocking: ',num2str(b), 'No available placement!'));
                curSeqAvailable = false;
                break;
            else
                % ���error=0�������λΪƽλ����LL�������
                if error>0 % ���error>0����MSS�������
                    colConsidered = MSS(curB,curPriori,col,bestStack);%curSeq(j),bestStack);

                    if colConsidered>0 %����MSS����������MSS������
                        if isempty(curOprs)
                            curOprs = strcat('<',int2str(curB(T-height(colConsidered)+1,colConsidered)),',',int2str(colConsidered),',',int2str(bestStack),'>');
%                             curOprs = strcat(curOprs,';<',int2str(b),',',int2str(col),',',int2str(bestStack),'>');
                        else
                            curOprs = strcat(curOprs,';<',int2str(curB(T-height(colConsidered)+1,colConsidered)),',',int2str(colConsidered),',',int2str(bestStack),'>');
%                             curOprs = strcat(curOprs,';<',int2str(b),',',int2str(col),',',int2str(bestStack),'>');
                        end
                        
                        curB(T-height(bestStack),bestStack)=curB(T-height(colConsidered)+1,colConsidered);
                        curPriori(T-height(bestStack),bestStack)=curPriori(T-height(colConsidered)+1,colConsidered);                        
                        curB(T-height(colConsidered)+1,colConsidered)=0;
                        curPriori(T-height(colConsidered)+1,colConsidered)=-1;
                        height(bestStack)=sum(curB(:,bestStack)~=0); 
                        height(colConsidered)=sum(curB(:,colConsidered)~=0); 
                        
                        minVector(bestStack)=minPriori(curPriori,bestStack);
                        min2Vector(bestStack)=minPrioriExceptTopmost(curPriori,bestStack); 
                        minVector(colConsidered)=minPriori(curPriori,colConsidered);
                        min2Vector(colConsidered)=minPrioriExceptTopmost(curPriori,colConsidered);   
                        
                        curCost=curCost+1;%MSS���򣬽�һ��������λ�ļ�װ���ƶ���bestStackջ������һ���������
                        
%                         disp(['error>0,LL+MSS,  curB(T-height(colConsidered)+1,colConsidered)=',num2str(curB(T-height(colConsidered)+1,colConsidered)),',  colConsidered=',num2str(colConsidered),',  bestStack=',num2str(bestStack)]);
                    end
                % MSS�������
                % ���error<0����FSS�������
                end
                if error<0
                    [colConsidered,colMovein,error_F] = FSS(curB,curPriori,b,col);
                    
                    if colConsidered>0 && colMovein>0
                        if isempty(curOprs)
                            curOprs = strcat('<',int2str(curB(T-height(colConsidered)+1,colConsidered)),',',int2str(colConsidered),',',int2str(colMovein),'>');
%                             curOprs = strcat(curOprs,';<',int2str(b),',',int2str(col),',',int2str(colConsidered),'>');
                            bestStack=colConsidered;
                        else
                            curOprs = strcat(curOprs,';<',int2str(curB(T-height(colConsidered)+1,colConsidered)),',',int2str(colConsidered),',',int2str(colMovein),'>');
%                             curOprs = strcat(curOprs,';<',int2str(b),',',int2str(col),',',int2str(colConsidered),'>');
                            bestStack=colConsidered;
                        end

                        curB(T-height(colMovein),colMovein)=curB(T-height(colConsidered)+1,colConsidered);
                        curPriori(T-height(colMovein),colMovein)=curPriori(T-height(colConsidered)+1,colConsidered);
                        curB(T-height(colConsidered)+1,colConsidered)=0;
                        curPriori(T-height(colConsidered)+1,colConsidered)=-1;
                        
                        height(colMovein)=sum(curB(:,colMovein)~=0);                        
                        minVector(colMovein)=minPriori(curPriori,colMovein);
                        min2Vector(colMovein)=minPrioriExceptTopmost(curPriori,colMovein);
                        height(colConsidered)=sum(curB(:,colConsidered)~=0);                        
                        minVector(colConsidered)=minPriori(curPriori,colConsidered);
                        min2Vector(colConsidered)=minPrioriExceptTopmost(curPriori,colConsidered);
                        
                        if error_F>0
                            curCost=curCost+1;%�ƶ�һ����װ��Ϊ��ǰ�谭���ڳ�һ��˳λ
                        elseif error_F==0
                            m=sum(curPriori(:,colMovein)==minVector(colMovein));
                            curCost=curCost+1+1-1/m;%�ƶ�һ����װ��Ϊ��ǰ�谭���ڳ�һ��ƽλ
                        end
                        
%                         disp(['error<0,LL+FSS,  curB(T-height(colConsidered)+1,colConsidered)=',num2str(curB(T-height(colConsidered)+1,colConsidered)),',  colConsidered=',num2str(colConsidered),',  colMovein=',num2str(colMovein)]);
                    end
                    % FSS�������
                end
                % �ƶ��谭��b����������ǰ�谭��
                if isempty(curOprs)
                    curOprs = strcat('<',int2str(b),',',int2str(col),',',int2str(bestStack),'>');
                else
                    curOprs = strcat(curOprs,';<',int2str(b),',',int2str(col),',',int2str(bestStack),'>');
                end
                
                curB(T-height(bestStack),bestStack)=b;
                curPriori(T-height(bestStack),bestStack)=p;
                curB(T-height(col)+1,col)=0;
                curPriori(T-height(col)+1,col)=-1;
                height(bestStack)=sum(curB(:,bestStack)~=0);
                height(col)=sum(curB(:,col)~=0);
                minVector(bestStack)=minPriori(curPriori,bestStack);
                min2Vector(bestStack)=minPrioriExceptTopmost(curPriori,bestStack);
                minVector(col)=minPriori(curPriori,col);
                min2Vector(col)=minPrioriExceptTopmost(curPriori,col);
                
                if error==0
                    m=sum(curPriori(:,bestStack)==p);
                    curCost=curCost+1-1/m;
                elseif error<0
                    if bestStack~=colConsidered
                        curCost=curCost+1; %�ƶ���һ���谭��
                    end
                    colConsidered=0;
                end
                
                % ����֮�󣬼���Ƿ���ڶ���Ŀ���䣬�������ֱ����ȡ
                hasTop=true;
                while hasTop
                    [topIds, topPrioris] = Tops(curB, curPriori);
                    hasTop=false;
                    for s=1:S
                        if s==col
                            continue;
                        end
                        if topPrioris(s)==0
                            hasTop=true;
                            if isempty(curOprs)
                                curOprs = strcat('<',int2str(topIds(s)),',',int2str(s),',0>');
                            else
                                curOprs = strcat(curOprs,';<',int2str(topIds(s)),',',int2str(s),',0>');
                            end
                            
                            curB(T-height(s)+1,s)=0;
                            curPriori(T-height(s)+1,s)=-1;
                            height(s)=sum(curB(:,s)~=0);
                            minVector(s)=minPriori(curPriori,s);
                            min2Vector(s)=minPrioriExceptTopmost(curPriori,s);
                            
                            [li,loc]=ismember(topIds(s),curSeq);
                            if li
                                curSeq(:,loc)=[];
                            end
                        end
                    end
                end
            end
            
            if ~curSeqAvailable
                break;
            end
        end
        if T-height(col)+1<row
            break; %������ֹ��ѡλ�����У�
        else
%             % ��ȡĿ����
%     %         [row,col]=find(curB==curSeq(j));
%             if isempty(curOprs)
%                 curOprs = strcat('<',int2str(curSeq(1)),',',int2str(col),',0>');
%             else
%                 curOprs = strcat(curOprs,';<',int2str(curSeq(1)),',',int2str(col),',0>');
%             end
%             curB(row,col)=0;
%             curPriori(row,col)=-1;
%             curSeq(:,1)=[];
%             height(col)=sum(curB(:,col)~=0);

            % ��ȡĿ����֮�󣬼���·��Ƿ񶥲�Ŀ���䣬�������ֱ����ȡ
            while height(col)>0 && curPriori(T-height(col)+1,col)==0
                if isempty(curOprs)
                    curOprs = strcat('<',int2str(curB(T-height(col)+1,col)),',',int2str(col),',0>');
                else
                    curOprs = strcat(curOprs,';<',int2str(curB(T-height(col)+1,col)),',',int2str(col),',0>');
                end
                
                curB(T-height(col)+1,col)=0;
                curPriori(T-height(col)+1,col)=-1;
                [li,loc]=ismember(curB(T-height(col)+1,col),curSeq);
                if li
                    curSeq(:,loc)=[];
                end
                height(col)=sum(curB(:,col)~=0);
                minVector(col)=minPriori(curPriori,col);
                min2Vector(col)=minPrioriExceptTopmost(curPriori,col);
            end
        end
    end
    if ~curSeqAvailable
        disp('Not available!');
%         break;
    else
        if curCost<minCost
            minCost=curCost;
            actions=curOprs;
            Bid_res=curB;
            Bpriori_res=curPriori;
        end
    end
end
nReloc = minCost;
Batch_res = Batch_new;

% 
%         %��ȡĿ������谭�伯��
%         blockings = curB(T-height(col)+1:row-1,col);
%         if ~isempty(blockings) %��������谭�䣬����з���ѡλ����
%             for y=1:length(blockings)
%                 b = blockings(y);
%                 if b==0
%                     continue;
%                 end
%                 % ���¼����ջ�Ĳ��
%                 height = sum(curB~=0);
%                 
%                 l = T-height(col)+1;  %��ǰ�谭��λ��ջ��
%                 p=curPriori(l,col);
%                 
%                 [bestStack,error] = FindBestPlacement(b,curB,curPriori);
%                 
%                 if bestStack==0
%                     disp(strcat('Round: ',num2str(k), 'Blocking: ',num2str(b), 'No available placement!'));
%                     curSeqAvailable = false;
%                     break;
%                 else
%                     % ���error=0�������λΪƽλ����LL�������
%                     if error ==0
%                         if isempty(curOprs)
%                             curOprs = strcat('<',int2str(b),',',int2str(col),',',int2str(bestStack),'>');
%                         else
%                             curOprs = strcat(curOprs,';<',int2str(b),',',int2str(col),',',int2str(bestStack),'>');
%                         end
%                         curB(T-height(bestStack),bestStack)=b;
%                         curPriori(T-height(bestStack),bestStack)=p;
%                         curB(l,col)=0;
%                         curPriori(l,col)=-1;
% 
%                         m=sum(curPriori(:,bestStack)==p);
%                         curCost=curCost+1-1/m;
%                     % LL�������
%                     % ���error>0����MSS�������
%                     elseif error>0
%                         colConsidered = MSS(curB,curPriori,curSeq(j),bestStack);
%                         if colConsidered==0 || T-height(bestStack)<2 %������MSS������
%                             if isempty(curOprs)
%                                 curOprs = strcat('<',int2str(b),',',int2str(col),',',int2str(bestStack),'>');
%                             else
%                                 curOprs = strcat(curOprs,';<',int2str(b),',',int2str(col),',',int2str(bestStack),'>');
%                             end
% 
%                             curB(T-height(bestStack),bestStack)=b;
%                             curPriori(T-height(bestStack),bestStack)=p;
%                             curB(l,col)=0;
%                             curPriori(l,col)=-1;
%                         else
%                             if isempty(curOprs)
%                                 curOprs = strcat('<',int2str(curB(T-height(colConsidered)+1,colConsidered)),',',int2str(colConsidered),',',int2str(bestStack),'>');
%                                 curOprs = strcat(curOprs,';<',int2str(b),',',int2str(col),',',int2str(bestStack),'>');
%                             else
%                                 curOprs = strcat(curOprs,';<',int2str(curB(T-height(colConsidered)+1,colConsidered)),',',int2str(colConsidered),',',int2str(bestStack),'>');
%                                 curOprs = strcat(curOprs,';<',int2str(b),',',int2str(col),',',int2str(bestStack),'>');
%                             end
%                             curB(T-height(bestStack),bestStack)=curB(T-height(colConsidered)+1,colConsidered);
%                             curB(T-height(bestStack)-1,bestStack)=b;
%                             curB(T-height(colConsidered)+1,colConsidered)=0;
%                             curB(l,col)=0;
%                             curPriori(T-height(bestStack),bestStack)=curPriori(T-height(colConsidered)+1,colConsidered);
%                             curPriori(T-height(bestStack)-1,bestStack)=p;
%                             curPriori(T-height(colConsidered)+1,colConsidered)=-1;
%                             curPriori(l,col)=-1;
%                             
%                             curCost=curCost+1;%MSS���򣬽�һ��������λ�ļ�װ���ƶ���bestStackջ������һ���������
%                         end
%                     % MSS�������
%                     % ���error<0����FSS�������
%                     else
%                         [colConsidered,colMovein,error_F] = FSS(curB,curPriori,curSeq(j));
%                         if colConsidered==0 || colMovein==0 %û�з���FSS�������λջ��ֱ�Ӱ�LL�������
%                             if isempty(curOprs)
%                                 curOprs = strcat('<',int2str(b),',',int2str(col),',',int2str(bestStack),'>');
%                             else
%                                 curOprs = strcat(curOprs,';<',int2str(b),',',int2str(col),',',int2str(bestStack),'>');
%                             end
%                             curB(T-height(bestStack),bestStack)=b;
%                             curB(l,col)=0;
%                             curPriori(T-height(bestStack),bestStack)=p; %curPriori(T-l+1,col);
%                             curPriori(l,col)=-1;
%                             
%                             curCost=curCost+1; %��λ��λջ������һ��ѹ��
%                         else
%                             if isempty(curOprs)
%                                 curOprs = strcat('<',int2str(curB(T-height(colConsidered)+1,colConsidered)),',',int2str(colConsidered),',',int2str(colMovein),'>');
%                                 curOprs = strcat(curOprs,';<',int2str(b),',',int2str(col),',',int2str(colConsidered),'>');
%                             else
%                                 curOprs = strcat(curOprs,';<',int2str(curB(T-height(colConsidered)+1,colConsidered)),',',int2str(colConsidered),',',int2str(colMovein),'>');
%                                 curOprs = strcat(curOprs,';<',int2str(b),',',int2str(col),',',int2str(colConsidered),'>');
%                             end
%                             
%                             curB(T-height(colMovein),colMovein)=curB(T-height(colConsidered)+1,colConsidered);
%                             curB(T-height(colConsidered)+1,colConsidered)=b;
%                             curB(l,col)=0;
%                             curPriori(T-height(colMovein),colMovein)=curPriori(T-height(colConsidered)+1,colConsidered);
%                             curPriori(T-height(colConsidered)+1,colConsidered)=p;
%                             curPriori(l,col)=-1;
%                             
%                             if error_F>0
%                                 curCost=curCost+1;%�ƶ�һ����װ��Ϊ��ǰ�谭���ڳ�һ��˳λ
%                             elseif error_F==0
%                                 m=sum(curPriori(:,colMovein)==curPriori(T-height(colMovein),colMovein));
%                                 curCost=curCost+1+1-1/m;%�ƶ�һ����װ��Ϊ��ǰ�谭���ڳ�һ��ƽλ
%                             end
%                         end
%                         % FSS�������
%                     end
%                     curCost=curCost+1; %�ƶ���һ���谭��
%                 end
%             end
%         end %�谭�䷭��ѡλ�������
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
%         Bid_res=curB;
%         Bpriori_res=curPriori;
%     end
% end
% nReloc = minCost;
