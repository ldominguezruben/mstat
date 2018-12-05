function [Migra]=mStat_Migration(geovar,handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MIGRATION DETERMINATE 
% Dominguez Ruben L. UNL
% This function calculate the migration between two centerline of a delta
% time t0 and t1. Define 4 normal lines from centerline t0 and calculate the
% distance from t0 to t1 centerline. This is the punctual migration. Also
% calculate the migration determinating the Migration Area between the length
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

init=1;%tinitial
ended=2;%tfinal

%Initial data
xstart=geovar{init}.equallySpacedX;
ystart=geovar{init}.equallySpacedY;

%Xstart mid point
for i=1:size(xstart,1)-1
    Xmidpoint(i,1)=(xstart(i+1,1)+xstart(i,1))/2;
    Ymidpoint(i,1)=(ystart(i+1,1)+ystart(i,1))/2;
end

%Finally data
xend=geovar{ended}.equallySpacedX;
yend=geovar{ended}.equallySpacedY;
% 

%%
%Define normal lines
%line1
dy=gradient(ystart);
dx=gradient(xstart);

for i=1:size(xstart,1)-1
    startpoint(i,:)=[xstart(i,1) ystart(i,1)];
    endpoint(i,:)=[xstart(i+1,1) ystart(i+1,1)];
    v(i,:)=endpoint(i,:)-startpoint(i,:);
    
    space=0.25;
    Migra.porcenVector=0:space:1-space;
    
    %Migra.porcenVector=[ 0.5 ];%4 points
    
    xx(i,:)=xstart(i,1)+Migra.porcenVector*v(i,1);%only one line in the middle

    yy(i,:)=ystart(i,1)+Migra.porcenVector*v(i,2);%only one line in the middle

    %Determinate the times 
    times=(nanmin(geovar{2}.wavelengthOfBends)/geovar{1}.width);%reduce the minimum wavelength and width �Como calculamos un valor correcto?
    
    mag=geovar{2}.width*times;%
    v(i,:)=mag*v(i,:)/norm(v(i,:));
    
    xstart_line1(i,:)=xx(i,:)+v(i,2);%extended line start
	xend_line1(i,:)=xx(i,:)-v(i,2);%extended line end
	ystart_line1(i,:)=yy(i,:)-v(i,1); 
	yend_line1(i,:)=yy(i,:)+v(i,1);
end

 clear startpoint endpoint

%  figure(3)
%     plot(xstart,ystart,'-b')%start
%     	hold on
%     plot(xend,yend,'-k')
%   for i=1:length(xend_line1)-1
%   hold on
%      line([xx(i,1)+v(i,2), xx(i,1)-v(i,2)],[yy(i,1)-v(i,1),yy(i,1)+v(i,1)])
%  end
% %  plot(xend_line1,yend_line1,'-k')
% 
% %  quiver(xstart,ystart,-dy,dx)
%   axis equal

robust=3;
active.ac=1;
setappdata(0, 'active', active);
%Intersection betwen extended normal line(t0) to centerline t1
%t1
for i=1:length(xstart_line1)-1
    for u=1:length(Migra.porcenVector)
    if isnan(xstart_line1(i,u)) | isnan(xend_line1(i,u)) | isnan(ystart_line1(i,u)) | isnan(yend_line1(i,u)) 
        xline1_int{u}(:,i)=nan;
        yline1_int{u}(:,i)=nan;
    else
        X11{u}(:,i)=[xstart_line1(i,u);xend_line1(i,u)];
        Y22{u}(:,i)=[ystart_line1(i,u);yend_line1(i,u)];
        %Find the intersection
        [xline1_int{u}(:,i),yline1_int{u}(:,i),~,~] = intersections(X11{u}(:,i),Y22{u}(:,i),xend,yend,robust);
    end
%     figure(3)
%     plot(xline1_int{u}(1,i),yline1_int{u}(1,i),'or')
%     hold on
%     plot(xstart,ystart,'-r')
%     plot(xend,yend,'-g')
    end
end 
clear X11 Y22



%t0
for i=1:length(xstart_line1)-1
    for u=1:length(Migra.porcenVector)
    if isnan(xstart_line1(i,u)) | isnan(xend_line1(i,u)) | isnan(ystart_line1(i,u)) | isnan(yend_line1(i,u)) 
        xline1_int{u}(:,i)=nan;
        yline1_int{u}(:,i)=nan;
    else
        X11{u}(:,i)=[xstart_line1(i,u);xend_line1(i,u)];
        Y22{u}(:,i)=[ystart_line1(i,u);yend_line1(i,u)];
    [xline2_int{u}(:,i),yline2_int{u}(:,i),~,~] = intersections(X11{u}(:,i),Y22{u}(:,i),xstart,ystart,robust);
    end
    end
end
clear X11 Y22


%%
%Calculate the distance

for i=1:length(xline1_int{1})
    
    for n=1:length(Migra.porcenVector)
    MigrationSignal{n}(i,1)=((xline1_int{n}(i)-xline2_int{n}(i))^2+(yline1_int{n}(i)-yline2_int{n}(i))^2)^0.5;
    
    u = xline1_int{n}(i)-xline2_int{n}(i);
    v = yline1_int{n}(i)-yline2_int{n}(i);
    anglq = atan2d(u,v);                                    % Angle Corrected For Quadrant
    Angles360 = @(a) rem(360+a, 360);                       % For �atan2d�
    Direction{n}(i,1)= Angles360(anglq);
    clear u v
        
    end
end

%Define the distance only if exist intersection
t=1;
for e=1:length(Direction{n})
    for n=1:length(Migra.porcenVector)
        if n==1
            Migra.MigrationDistance(t,1)=geovar{1}.sResample(e,1);
            Migra.MigrationSignal(t,1)=MigrationSignal{n}(e,1);
            Migra.Direction(t,1)=Direction{n}(e,1);
            Migra.xline2_int(t,1)=xline2_int{n}(1,e);%t0
            Migra.yline2_int(t,1)=yline2_int{n}(1,e);%t0
            Migra.xline1_int(t,1)=xline1_int{n}(1,e);%t1
            Migra.yline1_int(t,1)=yline1_int{n}(1,e);%t1
            t=t+1;
        else
            Migra.MigrationDistance(t,1)=(n-1)*0.25*(geovar{1}.sResample(e+1,1)-geovar{1}.sResample(e,1))+geovar{1}.sResample(e,1);
            Migra.MigrationSignal(t,1)=MigrationSignal{n}(e,1);
            Migra.Direction(t,1)=Direction{n}(e,1);
            Migra.xline2_int(t,1)=xline2_int{n}(1,e);%t0
            Migra.yline2_int(t,1)=yline2_int{n}(1,e);%t0
            Migra.xline1_int(t,1)=xline1_int{n}(1,e);%t1
            Migra.yline1_int(t,1)=yline1_int{n}(1,e);%t1
            t=t+1;
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Intersection lines both centerlines and the determination of area and
%the length to calculate Migration=Area/length
robust=0;
active.ac=0;
setappdata(0, 'active', active);

[ArMigra.xint_areat0,ArMigra.yint_areat0,iout0,jout0]=intersections...
    (geovar{1}.equallySpacedX,geovar{1}.equallySpacedY,...
    geovar{2}.equallySpacedX,geovar{2}.equallySpacedY,robust);

[ArMigra.xint_areat1,ArMigra.yint_areat1,iout1,jout1]=intersections...
    (geovar{2}.equallySpacedX,geovar{2}.equallySpacedY,...
    geovar{1}.equallySpacedX,geovar{1}.equallySpacedY,robust);

%Incopororate point to lines
%line t0

for t=1:length(ArMigra.xint_areat0)-1
    m=1;
    for r=1:length(geovar{1}.equallySpacedX)
        if r<iout0(t) & iout0(t)<r+1 %determina el primer nodo interseccion de una area abierta
            lineax(m)=ArMigra.xint_areat0(t);
            lineay(m)=ArMigra.yint_areat0(t);
            distancia(m)=0;
            indice(m)=r;
            m=m+1;
        elseif iout0(t)<r & iout0(t+1)>r %nodos internos de una area cerrada
            lineax(m)=geovar{1}.equallySpacedX(r);
            lineay(m)=geovar{1}.equallySpacedY(r);
            distancia(m)=((lineax(m)-lineax(m-1))^2+(lineay(m)-lineay(m-1))^2)^0.5;
            indice(m)=r;
            m=m+1;
        elseif r>iout0(t+1) %nodo final del area abierta
            lineax(m)=ArMigra.xint_areat0(t+1);
            lineay(m)=ArMigra.yint_areat0(t+1);
            indice(m)=r;
            distancia(m)=((lineax(m)-lineax(m-1))^2+(lineay(m)-lineay(m-1))^2)^0.5;
            m=m+1;
            break
        end
    end
    Migra.linet0X{t}.linea=lineax;
    Migra.linet0Y{t}.linea=lineay;
    Migra.Indext0{t}.ind=indice;
    Migra.distanciat0{t}=nansum(distancia);
    clear m lineax lineay distancia indice
end

% %line t1
for t=1:length(ArMigra.xint_areat1)-1%number of Migration areas founds
    m=1;
    for r=1:length(geovar{2}.equallySpacedX)
        if r<iout1(t) & iout1(t)<r+1%determina el primer nodo interseccion de una area abierta
            lineax(m)=ArMigra.xint_areat1(t);
            lineay(m)=ArMigra.yint_areat1(t);
            distancia(m)=0;
            indice(m)=r;
            m=m+1;
        elseif iout1(t)<r & iout1(t+1)>r%nodos internos de una area cerrada
            lineax(m)=geovar{2}.equallySpacedX(r);
            lineay(m)=geovar{2}.equallySpacedY(r);
            distancia(m)=((lineax(m)-lineax(m-1))^2+(lineay(m)-lineay(m-1))^2)^0.5;
            indice(m)=r;
            m=m+1;
        elseif r>iout1(t+1) %nodo final del area abierta
            lineax(m)=ArMigra.xint_areat1(t+1);
            lineay(m)=ArMigra.yint_areat1(t+1);
            distancia(m)=((lineax(m)-lineax(m-1))^2+(lineay(m)-lineay(m-1))^2)^0.5;
            indice(m)=r;
            break
        end
    end
    Migra.linet1X{t}.linea=lineax;
    Migra.linet1Y{t}.linea=lineay;
    Migra.Indext1{t}.ind=indice;
    Migra.distanciat1{t}=nansum(distancia);
%     figure(3)
%     plot(lineax,lineay,'-r','Linewidth',2)
%     hold on
%     plot(xstart,ystart,'-b')%start
%     plot(xend,yend,'-k')
%     plot(ArMigra.xint_areat0,ArMigra.yint_areat0,'or')
    clear m lineay lineax distancia indice
end    


%line t1
% for t=1:length(ArMigra.xint_areat1)-1
%     m=1;
%     for r=1:length(Migra.xline1_int)
%         if r<iout1(t) & iout1(t)<r+1%determina el primer nodo interseccion de una area abierta
%             lineax(m)=ArMigra.xint_areat1(t);
%             lineay(m)=ArMigra.yint_areat1(t);
%             distancia(m)=0;
%             indice(m)=r;
%             m=m+1;
%         elseif iout1(t)<r & iout1(t+1)>r%nodos internos de una area cerrada
%             lineax(m)=Migra.xline1_int(r);
%             lineay(m)=Migra.yline1_int(r);
%             distancia(m)=((lineax(m)-lineax(m-1))^2+(lineay(m)-lineay(m-1))^2)^0.5;
%             indice(m)=r;
%             m=m+1;
%         elseif r>iout1(t+1) %nodo final del area abierta
%             lineax(m)=ArMigra.xint_areat1(t+1);
%             lineay(m)=ArMigra.yint_areat1(t+1);
%             distancia(m)=((lineax(m)-lineax(m-1))^2+(lineay(m)-lineay(m-1))^2)^0.5;
%             indice(m)=r;
%             break
%         end
%     end
%     Migra.linet1X{t}.linea=lineax;
%     Migra.linet1Y{t}.linea=lineay;
%     Migra.Indext1{t}.ind=indice;
%     Migra.distanciat1{t}=nansum(distancia);
%         
%     figure(3)
%     plot(lineax,lineay,'-r','Linewidth',2)
%     hold on
%     plot(xstart,ystart,'-b')%start
%     plot(xend,yend,'-k')
%     plot(ArMigra.xint_areat0,ArMigra.yint_areat0,'or')
% 
%     clear m lineay lineax distancia indice
% end

for i=Migra.Indext1{1}.ind(1,1):Migra.Indext1{end}.ind(1,1)
%     if i<5 | i>length(xstart_line1)-5%quit first and end 5 point
%         Migra.cutoff(i)=nan;%none cut off
%     else
        if isnan(Migra.xline1_int(i)) %control if doesnt intersect
            Migra.cutoff(i)=i;%index cutt off
        else
            Migra.cutoff(i)=nan;%none cutoff
        end
%     end
end

%Calculate area
for t=1:length(ArMigra.xint_areat1)-1
	Migra.areat0(t)=trapz(Migra.linet0X{t}.linea,Migra.linet0Y{t}.linea);
	Migra.areat1(t)=trapz(Migra.linet1X{t}.linea,Migra.linet1Y{t}.linea);
	Migra.areat0_t1(t)=abs(Migra.areat0(t)-Migra.areat1(t));
end

%Migration
for t=1:length(ArMigra.xint_areat1)-1
	Migra.AreaTot(t)=Migra.areat0_t1(t)/(Migra.distanciat0{t}+Migra.distanciat1{t});
end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Go to wavelet analyzer to plot
SIGLVL=0.95;
sel=2;%inflection Method
filter=0;%No filter option
axest=[handles.wavel_axes];%axes of determination
Tools=2;%Migration tools

Migra.deltat=handles.year(2)-handles.year(1);%Delta time

mStat_plotWavel(geovar{1},sel,SIGLVL,filter,axest,Tools,Migra)

%%%Plot
hwait = waitbar(0,'Plotting...','Name','MStaT ',...
         'CreateCancelBtn',...
            'setappdata(gcbf,''canceling'',1)');
setappdata(hwait,'canceling',0)

axes(handles.pictureReach)

plot(xstart,ystart,'-b')%start
hold on
plot(xend,yend,'-k')
%plot(Migra.xline2_int,Migra.yline2_int,'ob')
plot(ArMigra.xint_areat0,ArMigra.yint_areat0,'or')
legend('t0','t1','Intersection','Location','Best')
grid on
axis equal
for t=2:length(Migra.xline1_int)
%line([xstart(t,1) xline1_int(1,t)],[ystart(t,1) yline1_int(1,t)])
%line([xstart_line1(t) xend_line1(t)],[ystart_line1(t) yend_line1(t)])
%line([xline2_int(t) xline1_int(t)],[yline2_int(t) yline1_int(t)])

% figure(3)
D=[Migra.xline1_int(t) Migra.yline1_int(t)]-[Migra.xline2_int(t) Migra.yline2_int(t)];
quiver(Migra.xline2_int(t),Migra.yline2_int(t),D(1),D(2),0,'filled','color','k','MarkerSize',10)
% plot(xline1_int{u}(1,i),yline1_int{u}(1,i),'or')
% hold on
% plot(xstart,ystart,'-r')
% plot(xend,yend,'-g')
% axis equal

%waitbar(((t/length(xline1_int))/50)/100,hwait); 
end
% 
xlabel('X [m]');ylabel('Y [m]')
hold off

waitbar(50/100,hwait);  
    
figure(3)
hold on
 plot(Migra.MigrationDistance,Migra.MigrationSignal/Migra.deltat,'-r');
xlabel('Intrinsic Channel Lengths [m]','Fontsize',10);
ylabel('Migration/year [m/yr]','Fontsize',10) 

%Plot migration
axes(handles.signalvariation);
[hAx,hLine1,hLine2] = plotyy(Migra.MigrationDistance,Migra.MigrationSignal/Migra.deltat,Migra.MigrationDistance,Migra.Direction,'plot');
hold on

xlabel('Intrinsic Channel Lengths [m]','Fontsize',10);
ylabel('Migration/year [m/yr]','Fontsize',10) % left y-axis

% Define limits
% FileBed_dataMX=Migra.MigrationDistance;
% xmin=min(FileBed_dataMX);     
% DeltaCentS=FileBed_dataMX(2,1)-FileBed_dataMX(1,1);  %units. 
% n=length((Migra.MigrationSignal/Migra.deltat)');
% xlim = [xmin,(n-1)*DeltaCentS+xmin];  % plotting range
% set(gca,'XLim',xlim(:));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%grid on
ylabel(hAx(1),'Migration/year [m/yr]','Fontsize',10) % left y-axis ylabel('Migration/year [m/yr]','Fontsize',10) % left y-axis
ylabel(hAx(2),'Direction [�]','Fontsize',10) % right y-axis
%set(hAx(1),'YLim',[0 nanmax(Migra.MigrationSignal/Migra.deltat)],'YTick',[0 nanmax(Migra.MigrationSignal/Migra.deltat)/2  nanmax(Migra.MigrationSignal/Migra.deltat)])
set(hAx(2),'YLim',[0 360],'YTick',[0 90 180 270 360])
hold off

hLine1.LineStyle = '-';
hLine2.LineStyle = '-.';

waitbar(100/100,hwait);
delete(hwait)
