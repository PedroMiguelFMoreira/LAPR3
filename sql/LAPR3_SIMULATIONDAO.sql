 CREATE OR REPLACE FUNCTION GETSIMULATIONLIST
  (
name_proj in PROJECT.NAME%TYPE
)return sys_refcursor

as 
  curNameSimulations  sys_refcursor;
  v_proj_id           project.project_id%type;

begin
  SELECT project_id   into v_proj_id
  FROM Project P
  WHERE P.name = name_proj;

  Open curNameSimulations 
  for 
      SELECT name 
      FROM Simulation S
      WHERE S.proj_id = v_proj_id;
      return curNameSimulations;
end getsimulationlist;
/
  CREATE OR REPLACE FUNCTION DELETESIMULATION
(
v_name SIMULATION.NAME%TYPE
)return number 

as
v_valor       number:=0;
name_find   simulation.name%TYPE;

begin
	begin
		SELECT name INTO name_find
		FROM Simulation S
		WHERE v_name = S.name;
	exception 
		when NO_DATA_FOUND THEN 
				name_find := NULL;
	end;
	
	if (name_find IS NOT NULL) then 
	 delete from simulation where v_name = name;
		v_valor := 1;
	end if;	
	
	return v_valor;
end deletesimulation;
/
  CREATE OR REPLACE PROCEDURE INSERTSIMULATION
  (
      proj_name              PROJECT.NAME%TYPE,
      simulation_name        SIMULATION.NAME%TYPE, 
      simulation_description SIMULATION.DESCRIPTION%TYPE
      )
IS
  proj_id INTEGER:=-1;

BEGIN
  SELECT P.PROJECT_ID into proj_id
  FROM PROJECT P
  WHERE P.NAME = proj_name;

  IF (PROJ_ID=-1) THEN
    RAISE_APPLICATION_ERROR(-20001,'Projeto com nome '|| proj_name ||'não existe');
  ELSE
    INSERT INTO SIMULATION(proj_id, simulation_id, name, description) 
    VALUES(proj_id, simulation_id.NEXTVAL, simulation_name, simulation_description); 
    DBMS_OUTPUT.PUT_LINE('Simulation created.');
  END IF;
END insertsimulation;
/
  CREATE OR REPLACE PROCEDURE INSERTTRAFFIC (simulation_name   SIMULATION.NAME%TYPE,
                                      vehicle_name	  		  VEHICLE.NAME%TYPE,
                                      traffic_arrival_rate	SIMULATION_TRAFFIC.ARRIVAL_RATE%TYPE,
                                      traffic_begin_node	  JUNCTION.NAME%TYPE,
                                      traffic_end_node	    JUNCTION.NAME%TYPE)
IS
	var_s_id SIMULATION.simulation_id%TYPE;
	var_p_id PROJECT.project_id%TYPE;
	var_v_id VEHICLE.vehicle_id%TYPE;
	var_begin_node JUNCTION.JUNCTION_ID%TYPE;
	var_end_node JUNCTION.JUNCTION_ID%TYPE;
BEGIN
	SELECT simulation_id into var_s_id FROM simulation S WHERE S.name=simulation_name;
	SELECT proj_id into var_p_id FROM simulation S WHERE S.simulation_id = var_s_id;
	SELECT vehicle_id into var_v_id FROM vehicle V WHERE V.name = vehicle_name and V.project_id = var_p_id;
	SELECT junction_id into var_begin_node FROM junction J WHERE J.name=traffic_begin_node and J.project_id = var_p_id;
	SELECT junction_id into var_end_node FROM junction J WHERE J.name=traffic_end_node and J.project_id = var_p_id;

	INSERT INTO SIMULATION_TRAFFIC(simulation_traffic_id, simulation_id, vehicle_id, arrival_rate, begin_node, end_node)
	VALUES (simulation_traffic_id.NEXTVAL, var_s_id, var_v_id, traffic_arrival_rate, var_begin_node, var_end_node);
	DBMS_OUTPUT.PUT_LINE('Simulation Traffic created.');
END insertTraffic;
/
  CREATE OR REPLACE FUNCTION GETSIMULATIONBYNAME (
  simulation_name SIMULATION.NAME%TYPE) 
RETURN sys_refcursor
AS
  sim_result sys_refcursor;
BEGIN
  OPEN sim_result FOR SELECT S.NAME,S.DESCRIPTION FROM SIMULATION S WHERE S.NAME = simulation_name; 
  return sim_result;
END;
/
  create or replace function getSimulationTraffic(
  simulation_name SIMULATION.NAME%TYPE) 
RETURN sys_refcursor
AS
  sim_result sys_refcursor;
BEGIN
  OPEN sim_result FOR 
    SELECT V.NAME AS v_name, ST.ARRIVAL_RATE AS arrival_rate, J.NAME AS begin_node, J2.NAME AS end_node
    FROM SIMULATION S,SIMULATION_TRAFFIC ST, Vehicle V, JUNCTION J, JUNCTION J2 
    WHERE S.NAME = simulation_name AND S.SIMULATION_ID=ST.SIMULATION_ID AND V.VEHICLE_ID=ST.VEHICLE_ID AND 
    ST.begin_node=J.JUNCTION_ID AND ST.END_NODE=J2.JUNCTION_ID;
  
  return sim_result;
END;
/
  CREATE OR REPLACE PROCEDURE UPDATESIMULATION (oldSimulationName SIMULATION.NAME%TYPE,
                                            newSimulationName Simulation.NAME%TYPE, 
                                            newSimulationDescription SIMULATION.DESCRIPTION%TYPE)
IS
  s_id SIMULATION.simulation_id%TYPE;
BEGIN
  SELECT simulation_id into s_id FROM simulation S where S.name=oldSimulationName;
  UPDATE simulation S SET S.name=newSimulationName, S.description=newSimulationDescription WHERE s_id=S.simulation_id;

END updateSimulation;
/
CREATE OR REPLACE PROCEDURE INSERTSIMULATIONRUNDATA(
  SIMULATION_NAME SIMULATION.NAME%TYPE,
  SIMULATION_RUN_NAME SIMULATION_RUN.NAME%TYPE,
  SR_START_TIME SIMULATION_RUN.START_TIME%TYPE,
  SR_END_TIME SIMULATION_RUN.END_TIME%TYPE,
  SR_TIME_STEP SIMULATION_RUN.TIME_STEP%TYPE,
  NAME_ALGORITHM SIM_ALGORITHM.NAME%TYPE)
  
IS
  V_SIMULATION_ID SIMULATION.SIMULATION_ID%TYPE;
  V_ALGORITHM_ID SIM_ALGORITHM.SIM_ALGORITHM_ID%TYPE;
BEGIN 
    SELECT simulation_id into V_SIMULATION_ID FROM SIMULATION S WHERE S.NAME=SIMULATION_NAME;
    SELECT sim_algorithm_id into V_ALGORITHM_ID FROM sim_algorithm S WHERE S.NAME=NAME_ALGORITHM;
    INSERT INTO SIMULATION_RUN(SIMULATION_RUN_ID, SIMULATION_ID, NAME, START_TIME, END_TIME, TIME_STEP, ALGORITHM_ID) 
      VALUES(SIMULATION_RUN_ID.NEXTVAL, V_SIMULATION_ID, SIMULATION_RUN_NAME, SR_START_TIME, SR_END_TIME, SR_TIME_STEP, V_ALGORITHM_ID);
  
END INSERTSIMULATIONRUNDATA;
/
CREATE OR REPLACE PROCEDURE INSERTSIMULATIONRUNVEHICLE (
  BEGIN_NODE_NAME JUNCTION.NAME%TYPE,
  END_NODE_NAME JUNCTION.NAME%TYPE,
  VEHICLE_NAME VEHICLE.NAME%TYPE,
  SIMULATION_RUN_NAME SIMULATION_RUN.NAME%TYPE,
  INSTANT_DROPPED_OUT SIM_RUN_VEHICLE.INSTANT_DROPPED_OUT%TYPE)
IS
  V_SIMULATION_ID SIMULATION.SIMULATION_ID%TYPE;
  V_PROJ_ID PROJECT.PROJECT_ID%TYPE;
  V_BEGIN_NODE_ID JUNCTION.JUNCTION_ID%TYPE;
  V_END_NODE_ID JUNCTION.JUNCTION_ID%TYPE;
  V_VEHICLE_ID VEHICLE.VEHICLE_ID%TYPE;
  V_SIMULATION_TRAFFIC_ID SIMULATION_TRAFFIC.SIMULATION_TRAFFIC_ID%TYPE;
  V_SIMULATION_RUN_ID SIMULATION_RUN.SIMULATION_RUN_ID%TYPE;
BEGIN
  SELECT SIMULATION_RUN_ID INTO V_SIMULATION_RUN_ID FROM SIMULATION_RUN S WHERE S.NAME = SIMULATION_RUN_NAME;
  SELECT SIMULATION_ID INTO V_SIMULATION_ID FROM SIMULATION_RUN S WHERE S.SIMULATION_RUN_ID = V_SIMULATION_RUN_ID;
  SELECT PROJ_ID INTO V_PROJ_ID FROM SIMULATION S WHERE S.SIMULATION_ID = V_SIMULATION_ID;
  SELECT JUNCTION_ID INTO V_BEGIN_NODE_ID FROM JUNCTION J WHERE J.PROJECT_ID = V_PROJ_ID AND J.NAME = BEGIN_NODE_NAME;
  SELECT JUNCTION_ID INTO V_END_NODE_ID FROM JUNCTION J WHERE J.PROJECT_ID = V_PROJ_ID AND J.NAME = END_NODE_NAME;
  SELECT VEHICLE_ID INTO V_VEHICLE_ID FROM VEHICLE V WHERE V.NAME = VEHICLE_NAME AND V.PROJECT_ID = V_PROJ_ID;
  SELECT SIMULATION_TRAFFIC_ID INTO V_SIMULATION_TRAFFIC_ID FROM SIMULATION_TRAFFIC S WHERE S.SIMULATION_ID = V_SIMULATION_ID AND S.BEGIN_NODE = V_BEGIN_NODE_ID AND S.END_NODE = V_END_NODE_ID AND S.VEHICLE_ID = V_VEHICLE_ID;

  INSERT INTO SIM_RUN_VEHICLE(SIM_RUN_VEHICLE_ID, SIM_RUN_ID, SIMULATION_TRAFFIC_ID, INSTANT_DROPPED_OUT)
  VALUES(SIM_RUN_VEHICLE_ID.NEXTVAL, V_SIMULATION_RUN_ID, V_SIMULATION_TRAFFIC_ID, INSTANT_DROPPED_OUT);
END INSERTSIMULATIONRUNVEHICLE;
 /
CREATE OR REPLACE PROCEDURE INSERTSIMRUNVEHICLERESULTS 
(
  VEHICLE_NAME VEHICLE.NAME%TYPE 
, PROJECT_NAME PROJECT.NAME%TYPE
, INSTANT_IN SIM_RUN_VEHICLE_RESULT.INSTANT_IN%TYPE
, INSTANT_OUT SIM_RUN_VEHICLE_RESULT.INSTANT_OUT%TYPE
, ENERGY SIM_RUN_VEHICLE_RESULT.ENERGY%TYPE
, ROAD_NAME SECTION.ROAD_NAME%TYPE
, INDEX_SEGMENT SEGMENT.S_INDEX%TYPE
) 
AS 
  V_PROJ_ID PROJECT.PROJECT_ID%TYPE;
  V_VEHICLE_ID VEHICLE.VEHICLE_ID%TYPE;
  V_SEGMENT_ID SECTION.SECTION_ID%TYPE;
BEGIN
  SELECT PROJECT_ID INTO V_PROJ_ID FROM PROJECT P WHERE P.NAME = PROJECT_NAME;
  SELECT VEHICLE_ID INTO V_VEHICLE_ID FROM VEHICLE V WHERE V.NAME = VEHICLE_NAME AND V.PROJECT_ID = V_PROJ_ID;
  SELECT SEGMENT_ID INTO V_SEGMENT_ID FROM SEGMENT S WHERE S.S_INDEX = INDEX_SEGMENT AND S.SECTION_ID = (
      SELECT SECTION_ID FROM SECTION S WHERE S.ROAD_NAME = ROAD_NAME AND S.PROJECT_ID = V_PROJ_ID);
      
  INSERT INTO SIM_RUN_VEHICLE_RESULT(SIM_RUN_VEHICLE_RESULT_ID, SIM_VEHICLE_ID, INSTANT_IN, INSTANT_OUT, ENERGY, SEGMENT_ID)
  VALUES(SIM_RUN_VEHICLE_RESULT_ID.NEXTVAL, V_VEHICLE_ID, INSTANT_IN, INSTANT_OUT, ENERGY, V_SEGMENT_ID);
  
END INSERTSIMRUNVEHICLERESULTS;
/
create or replace function getSimulationRunList(
  simulation_name SIMULATION.NAME%TYPE) 
RETURN sys_refcursor
AS
  sim_result sys_refcursor;
BEGIN
  OPEN sim_result FOR 
    
    
    SELECT name 
      FROM SIMULATION_RUN S
      WHERE S.SIMULATION_ID = (SELECT SIMULATION_ID 
                                FROM SIMULATION WHERE S.NAME=simulation_name);
  
  return sim_result;
END;
/
create or replace function getSimulationRunByName(
  simulation_run_name SIMULATION_RUN.NAME%TYPE) 
RETURN sys_refcursor
AS
  sim_result sys_refcursor;
BEGIN
  OPEN sim_result FOR SELECT S.* FROM SIMULATION_RUN S WHERE S.NAME = simulation_run_name; 
  return sim_result;
END;
/
create or replace function getSimulationRunVehicle(
  simulation_name SIMULATION.NAME%TYPE,
  simulation_run_name SIMULATION_RUN.NAME%TYPE) 
RETURN sys_refcursor
AS
  sim_result sys_refcursor;
  sRID SIMULATION_RUN.SIMULATION_RUN_ID%TYPE;
BEGIN
  SELECT S.SIMULATION_RUN_ID INTO sRID FROM SIMULATION_RUN S WHERE S.NAME = simulation_run_name;
  OPEN sim_result FOR 
  
    SELECT V.NAME AS v_name, J.NAME AS begin_node, J2.NAME AS end_node, SV.INSTANT_DROPPED_OUT as inst_drop
    FROM SIMULATION S, SIMULATION_TRAFFIC ST, Vehicle V, JUNCTION J, JUNCTION J2, SIM_RUN_VEHICLE SV 
    WHERE SV.SIM_RUN_ID=sRID AND S.NAME = simulation_name AND S.SIMULATION_ID=ST.SIMULATION_ID AND V.VEHICLE_ID=ST.VEHICLE_ID AND 
    ST.begin_node=J.JUNCTION_ID AND ST.END_NODE=J2.JUNCTION_ID;
    
  return sim_result;
END;
/
create or replace PROCEDURE INSERTSIMULATIONRUNVEHICLE (
  BEGIN_NODE_NAME JUNCTION.NAME%TYPE,
  END_NODE_NAME JUNCTION.NAME%TYPE,
  SIMULATION_NAME SIMULATION.NAME%TYPE,
  VEHICLE_NAME VEHICLE.NAME%TYPE,
  SIMULATION_RUN_NAME SIMULATION_RUN.NAME%TYPE,
  INSTANT_DROPPED_OUT SIM_RUN_VEHICLE.INSTANT_DROPPED_OUT%TYPE,
  INS_ID SIM_RUN_VEHICLE.INSTANCE_ID%TYPE)
IS
  V_SIMULATION_ID SIMULATION.SIMULATION_ID%TYPE;
  V_PROJ_ID PROJECT.PROJECT_ID%TYPE;
  V_BEGIN_NODE_ID JUNCTION.JUNCTION_ID%TYPE;
  V_END_NODE_ID JUNCTION.JUNCTION_ID%TYPE;
  V_VEHICLE_ID VEHICLE.VEHICLE_ID%TYPE;
  V_SIMULATION_TRAFFIC_ID SIMULATION_TRAFFIC.SIMULATION_TRAFFIC_ID%TYPE;
  V_SIMULATION_RUN_ID SIMULATION_RUN.SIMULATION_RUN_ID%TYPE;
BEGIN
  SELECT SIMULATION_ID INTO V_SIMULATION_ID FROM SIMULATION S WHERE S.NAME = SIMULATION_NAME;
  SELECT SIMULATION_RUN_ID INTO V_SIMULATION_RUN_ID FROM SIMULATION_RUN S WHERE S.NAME = SIMULATION_RUN_NAME AND S.SIMULATION_ID = V_SIMULATION_ID;
  SELECT PROJ_ID INTO V_PROJ_ID FROM SIMULATION S WHERE S.SIMULATION_ID = V_SIMULATION_ID;
  SELECT JUNCTION_ID INTO V_BEGIN_NODE_ID FROM JUNCTION J WHERE J.PROJECT_ID = V_PROJ_ID AND J.NAME = BEGIN_NODE_NAME;
  SELECT JUNCTION_ID INTO V_END_NODE_ID FROM JUNCTION J WHERE J.PROJECT_ID = V_PROJ_ID AND J.NAME = END_NODE_NAME;
  SELECT VEHICLE_ID INTO V_VEHICLE_ID FROM VEHICLE V WHERE V.NAME = VEHICLE_NAME AND V.PROJECT_ID = V_PROJ_ID;
  SELECT SIMULATION_TRAFFIC_ID INTO V_SIMULATION_TRAFFIC_ID FROM SIMULATION_TRAFFIC S WHERE S.SIMULATION_ID = V_SIMULATION_ID AND S.BEGIN_NODE = V_BEGIN_NODE_ID AND S.END_NODE = V_END_NODE_ID AND S.VEHICLE_ID = V_VEHICLE_ID;

  INSERT INTO SIM_RUN_VEHICLE(SIM_RUN_VEHICLE_ID, SIM_RUN_ID, SIMULATION_TRAFFIC_ID, INSTANT_DROPPED_OUT, INSTANCE_ID)
  VALUES(SIM_RUN_VEHICLE_ID.NEXTVAL, V_SIMULATION_RUN_ID, V_SIMULATION_TRAFFIC_ID, INSTANT_DROPPED_OUT, INS_ID);
END INSERTSIMULATIONRUNVEHICLE;
/
create or replace PROCEDURE INSERTSIMRUNVEHICLERESULTS 
(
  PROJECT_NAME PROJECT.NAME%TYPE,
  VEHICLE_NAME VEHICLE.NAME%TYPE, 
  BEGIN_NODE_NAME JUNCTION.NAME%TYPE,
  END_NODE_NAME JUNCTION.NAME%TYPE,
  SIMULATION_NAME SIMULATION.NAME%TYPE,
  SIMULATION_RUN_NAME SIMULATION_RUN.NAME%TYPE,
  INSTANT_IN SIM_RUN_VEHICLE_RESULT.INSTANT_IN%TYPE, 
  INSTANT_OUT SIM_RUN_VEHICLE_RESULT.INSTANT_OUT%TYPE,
  ENERGY SIM_RUN_VEHICLE_RESULT.ENERGY%TYPE,
  ROAD SECTION.ROAD_NAME%TYPE,
  INDEX_SEGMENT SEGMENT.S_INDEX%TYPE,
  INS_ID SIM_RUN_VEHICLE.INSTANCE_ID%TYPE
) 
AS 
  V_PROJ_ID PROJECT.PROJECT_ID%TYPE;
  V_VEHICLE_ID VEHICLE.VEHICLE_ID%TYPE;
  V_BEGIN_NODE_ID JUNCTION.JUNCTION_ID%TYPE;
  V_END_NODE_ID JUNCTION.JUNCTION_ID%TYPE;
  V_SIMULATION_ID SIMULATION.SIMULATION_ID%TYPE;
  V_SIMULATION_TRAFFIC_ID SIMULATION_TRAFFIC.SIMULATION_TRAFFIC_ID%TYPE;
  V_SIMULATION_RUN_ID SIMULATION_RUN.SIMULATION_RUN_ID%TYPE;
  V_SIM_RUN_VEHICLE_ID SIM_RUN_VEHICLE.SIM_RUN_VEHICLE_ID%TYPE;
  V_SEGMENT_ID SECTION.SECTION_ID%TYPE;
BEGIN

  SELECT PROJECT_ID INTO V_PROJ_ID FROM PROJECT P WHERE P.NAME = PROJECT_NAME; 
  SELECT VEHICLE_ID INTO V_VEHICLE_ID FROM VEHICLE V WHERE V.NAME = VEHICLE_NAME AND V.PROJECT_ID = V_PROJ_ID;
  SELECT JUNCTION_ID INTO V_BEGIN_NODE_ID FROM JUNCTION J WHERE J.PROJECT_ID = V_PROJ_ID AND J.NAME = BEGIN_NODE_NAME;
  SELECT JUNCTION_ID INTO V_END_NODE_ID FROM JUNCTION J WHERE J.PROJECT_ID = V_PROJ_ID AND J.NAME = END_NODE_NAME;
  SELECT SIMULATION_ID INTO V_SIMULATION_ID FROM SIMULATION S WHERE S.NAME = SIMULATION_NAME;
  SELECT SIMULATION_TRAFFIC_ID INTO V_SIMULATION_TRAFFIC_ID FROM SIMULATION_TRAFFIC S WHERE S.SIMULATION_ID = V_SIMULATION_ID AND S.BEGIN_NODE = V_BEGIN_NODE_ID AND S.END_NODE = V_END_NODE_ID AND S.VEHICLE_ID = V_VEHICLE_ID;
  SELECT SIMULATION_RUN_ID INTO V_SIMULATION_RUN_ID FROM SIMULATION_RUN S WHERE S.NAME = SIMULATION_RUN_NAME AND S.SIMULATION_ID = V_SIMULATION_ID;
  
  SELECT SIM_RUN_VEHICLE_ID INTO V_SIM_RUN_VEHICLE_ID 
  FROM SIM_RUN_VEHICLE S 
  WHERE S.SIM_RUN_ID = V_SIMULATION_RUN_ID AND S.SIMULATION_TRAFFIC_ID = V_SIMULATION_TRAFFIC_ID AND S.INSTANCE_ID = INS_ID;

 SELECT SEGMENT_ID INTO V_SEGMENT_ID FROM SEGMENT S WHERE S.S_INDEX = INDEX_SEGMENT AND S.SECTION_ID = (
  SELECT SECTION_ID FROM SECTION S WHERE S.ROAD_NAME = ROAD AND S.PROJECT_ID = V_PROJ_ID);
      
  INSERT INTO SIM_RUN_VEHICLE_RESULT(SIM_RUN_VEHICLE_RESULT_ID, SIM_VEHICLE_ID, INSTANT_IN, INSTANT_OUT, ENERGY, SEGMENT_ID)
  VALUES(SIM_RUN_VEHICLE_RESULT_ID.NEXTVAL, V_SIM_RUN_VEHICLE_ID, INSTANT_IN, INSTANT_OUT, ENERGY, V_SEGMENT_ID);
  
END INSERTSIMRUNVEHICLERESULTS;