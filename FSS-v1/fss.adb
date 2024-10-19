
with Kernel.Serial_Output; use Kernel.Serial_Output;
with Ada.Real_Time; use Ada.Real_Time;
with System; use System;

with Tools; use Tools;
with devicesFSS_V1; use devicesFSS_V1;

-- NO ACTIVAR ESTE PAQUETE MIENTRAS NO SE TENGA PROGRAMADA LA INTERRUPCION
-- Packages needed to generate button interrupts       
-- with Ada.Interrupts.Names;
-- with Button_Interrupt; use Button_Interrupt;

package body fss is

    ----------------------------------------------------------------------
    ------------- procedure exported 
    ----------------------------------------------------------------------
    procedure Background is
    begin
      loop
        null;
      end loop;
    end Background;
    ----------------------------------------------------------------------

    -----------------------------------------------------------------------
    ------------- declaration of protected objects 
    -----------------------------------------------------------------------

    -- Aqui se declaran los objetos protegidos para los datos compartidos  


    -----------------------------------------------------------------------
    ------------- declaration of tasks 
    -----------------------------------------------------------------------

    -- Aqui se declaran las tareas que forman el STR


    -----------------------------------------------------------------------
    ------------- body of tasks 
    -----------------------------------------------------------------------

    -- Aqui se escriben los cuerpos de las tareas 


    ----------------------------------------------------------------------
    ------------- procedimientos para probar los dispositivos 
    ------------- SE DEBERÁN QUITAR PARA EL PROYECTO
    ----------------------------------------------------------------------
    procedure Prueba_Velocidad_Distancia; 
    procedure Prueba_Altitud_Joystick; 
    procedure Prueba_Sensores_Piloto;
    
    Procedure Prueba_Velocidad_Distancia is

        Current_Pw: Power_Samples_Type := 0;
        Current_S: Speed_Samples_Type := 500; 
        Calculated_S: Speed_Samples_type := 0; 
             
        Current_D: Distance_Samples_Type := 0;
        Current_L: Light_Samples_Type := 0;
        
    begin

         for I in 1..200 loop     -- Se limita a 200 iteraciones
         Start_Activity ("Prueba_Velocidad");        
                   
            -- Prueba potencia del piloto 
            Read_Power (Current_Pw);  -- lee la potencia de motor indicada por el piloto
            Display_Pilot_Power(Current_Pw);
                      
            -- transfiere la potencia/velocidad a la aeronave
            Calculated_S := Speed_Samples_type (float (Current_Pw) * 1.2); -- aplicar fórmula
            Current_S := Read_Speed;
            if (Calculated_S > 1000) then 
            	Set_Speed(1000);
            	Light_2(On);
	     elsif(Calculated_S < 300) then 
            	Set_Speed(300);
            	Light_2(On);
              else
	     	 Light_2(Off);
	     	 Set_Speed(Calculated_S);
            end if;           	
            
            -- Comprueba la velocidad real de la aeronave
            Current_S := Read_Speed;        -- lee la velocidad actual de la aeronave
            Display_Speed (Current_S);

            -- Prueba distancia con obstaculos
            Read_Distance (Current_D);
            if(Current_D <= 1000 )then
            	New_line;
            	Put("ROLLING...");
            	New_line;
            	Set_Aircraft_Roll(40);
            	Alarm(4);
	    elsif(Current_D <= 2000)then
             	Alarm(4);
            elsif(Current_D <=4000)then
             	Alarm(2);
            end if;
            Display_Distance (Current_D);
                                 
         Finish_Activity ("Prueba_Velocidad");   
         delay until (Clock + To_time_Span(0.1));
         end loop;


    end Prueba_Velocidad_Distancia;

    Procedure Prueba_Altitud_Joystick is
        
        Current_J: Joystick_Samples_Type := (0,0);
        Target_Pitch: Pitch_Samples_Type := 0;
        Target_Roll: Roll_Samples_Type := 0; 
        Aircraft_Pitch: Pitch_Samples_Type; 
        Aircraft_Roll: Roll_Samples_Type;
        
        Current_A: Altitude_Samples_Type := 8000;
        
    begin
         for I in 1..300 loop     
            Start_Activity ("Prueba_Altitud");
            
            -- Lee Joystick del piloto
            Read_Joystick (Current_J);
            
            -- establece Pitch y Roll en la aeronave
            Target_Pitch := Pitch_Samples_Type (Current_J(x));
            Target_Roll := Roll_Samples_Type (Current_J(y));
                                      
            Set_Aircraft_Pitch (Target_Pitch);  -- transfiere el movimiento pitch a la aeronave
            Set_Aircraft_Roll (Target_Roll);    -- transfiere el movimiento roll  a la aeronave 
                       
            Aircraft_Pitch := Read_Pitch;       -- lee la posición pitch de la aeronave
            Aircraft_Roll := Read_Roll;         -- lee la posición roll  de la aeronave
            
            Display_Joystick (Current_J);       -- muestra por display el joystick  
            Display_Pitch (Aircraft_Pitch);     -- muestra por display la posición de la aeronave  
            Display_Roll (Aircraft_Roll);

            -- Comprueba altitud
            Current_A := Read_Altitude;         -- lee y muestra por display la altitud de la aeronave  
            if(Current_A>= 10000)then
            	Light_2(On);
            end if;
            Display_Altitude (Current_A);
            
            if (Current_A > 9000) then Alarm (3); 
                                       Display_Message ("To high");
            end if; 
               
            Finish_Activity ("Prueba_Altitud");                      
         delay until (Clock + To_time_Span(0.1));
         end loop;

         Finish_Activity ("Prueba_Altitud");
    end Prueba_Altitud_Joystick;


    Procedure Prueba_Sensores_Piloto is
        Current_Pp: PilotPresence_Samples_Type := 1;
        Current_Pb: PilotButton_Samples_Type := 0;
    begin

         for I in 1..120 loop
            Start_Activity ("Prueba_Piloto");                
            -- Prueba presencia piloto
            Current_Pp := Read_PilotPresence;
            if (Current_Pp = 0) then Alarm (1); end if;   
            Display_Pilot_Presence (Current_Pp);
                 
            -- Prueba botón para selección de modo 
            Current_Pb := Read_PilotButton;            
            Display_Pilot_Button (Current_Pb); 
            
            Finish_Activity ("Prueba_Piloto");  
         delay until (Clock + To_time_Span(0.1));
         end loop;

         Finish_Activity ("Prueba_Piloto");
    end Prueba_Sensores_Piloto;


begin
   Start_Activity ("Programa Principal");
   Prueba_Velocidad_Distancia;
   -- Prueba_Altitud_Joystick;
   -- Prueba_Sensores_Piloto;
   Finish_Activity ("Programa Principal");
end fss;



