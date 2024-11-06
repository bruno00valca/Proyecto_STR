with Kernel.Serial_Output; use Kernel.Serial_Output;
with Ada.Real_Time;        use Ada.Real_Time;
with System;               use System;

with Tools;         use Tools;
with devicesFSS_V1;
use devicesFSS_V1;

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
   protected Cabeceo_Alabeo_Protegido is
      -- Funciones para obtener los valores de Pitch y Roll
      function Get_Pitch return Pitch_Samples_Type;
      function Get_Roll return Roll_Samples_Type;

      -- Procedimientos para ajustar los valores de Pitch y Roll
      procedure Set_Pitch (New_Pitch : Pitch_Samples_Type);
      procedure Set_Roll (New_Roll : Roll_Samples_Type);

   private
      Pitch : Pitch_Samples_Type := 0;
      Roll : Roll_Samples_Type := 0;
   end Cabeceo_Alabeo_Protegido;

   protected body Cabeceo_Alabeo_Protegido is
      function Get_Pitch return Pitch_Samples_Type is
      begin
         return Pitch;
      end Get_Pitch;

      function Get_Roll return Roll_Samples_Type is
      begin
         return Roll;
      end Get_Roll;

      procedure Set_Pitch (New_Pitch : Pitch_Samples_Type) is
      begin
         Pitch := New_Pitch;
      end Set_Pitch;

      procedure Set_Roll (New_Roll : Roll_Samples_Type) is
      begin
         Roll := New_Roll;
      end Set_Roll;
   end Cabeceo_Alabeo_Protegido;


   -----------------------------------------------------------------------
   ------------- declaration of tasks
   -----------------------------------------------------------------------

   -- Aqui se declaran las tareas que forman el STR
   task Speed is
      pragma Priority (3);
   end Speed;

   task Position_Altitude is
      pragma Priority(4);
    end Position_Altitude;

   -----------------------------------------------------------------------
   ------------- body of tasks
   -----------------------------------------------------------------------

   -- TAREA DE CONTROL DE VELOCIDAD

   task body Speed is

      Current_Pw   : Power_Samples_Type := 0;
      Current_S    : Speed_Samples_Type := 500;
      Calculated_S : Speed_Samples_type := 0;

      Current_D : Distance_Samples_Type := 0;
      Current_L : Light_Samples_Type := 0;

      Target_Pitch : Pitch_Samples_Type;
      Target_Roll  : Roll_Samples_Type;

    begin

      loop
         Start_Activity ("Task de velocidad");

         -- Prueba potencia del piloto

         Read_Power(Current_Pw);
         Display_Pilot_Power (Current_Pw);

         -- transfiere la potencia/velocidad a la aeronave
         
         Calculated_S := Speed_Samples_type (float (Current_Pw) * 1.2); 
         Current_S := Read_Speed;
         if (Calculated_S > 1000) then
            Set_Speed (1000);
            Light_2 (On);
         elsif (Calculated_S < 300) then
            Set_Speed (300);
            Light_2 (On);
         else
            Light_2 (Off);
            Set_Speed (Calculated_S);
         end if;

         Current_S := Read_Speed;
         Display_Speed (Current_S);

         -- Ajuste de la velocidad con las maniobras de cabeceo y alabeo

         Target_Pitch := Cabeceo_Alabeo_Protegido.Get_Pitch;
         Target_Roll := Cabeceo_Alabeo_Protegido.Get_Roll;

         -- Maniobra de Cabeceo y Alabeo

         if (Target_Pitch > 0 and Target_Roll > 0) and Current_S < 1000 then
            if Current_S + 250 > 1000 then
               New_line;
               Put("AJUSTANDO VELOCIDAD POR MANIOBRA ELABORADA");
               Set_Speed (1000);
               Light_2 (On);
            else
               Set_Speed (Current_S + 250);
            end if;

         -- Maniobra de Alabeo

         elsif Target_Roll /= 0 and Current_S < 1000 then 
            if Current_S + 100 > 1000 then
               New_line;
               Put("AJUSTANDO VELOCIDAD POR ALABEO");
               Set_Speed (1000);
               Light_2 (On);
            else
               Set_Speed (Current_S + 100);
            end if;

         -- Maniobra de Cabeceo

         elsif Target_Pitch > 0 and Current_S < 1000 then
            if Current_S + 150 > 1000 then
               New_line;
               Put("AJUSTANDO VELOCIDAD POR CABECEO");
               Set_Speed (1000);
               Light_2 (On);
            else
               Set_Speed (Current_S + 150);
            end if;
         end if;

         -- Manejo de velocidades límite
         
         if(Current_Pw < 300) then
            Alarm(2);
            if(Current_Pw <= 250) then
               Alarm(4);
               Current_Pw:= 300;
               New_line;
               Put("Incrementando Potencia a 300");                    
            end if;
         end if;
         Finish_Activity ("Task de Velocidad");
         delay until (Clock + To_time_Span (0.3));
      end loop;
      

    end Speed;

-- TAREA CONTROL DE POSICION Y ALTITUD

task body Position_Altitude is
   Current_J : Joystick_Samples_Type := (0, 0);
   Target_Pitch : Pitch_Samples_Type := 0;
   Current_A : Altitude_Samples_Type:= Initial_Altitude;

begin
   loop
      Start_Activity("Control_Cabeceo_Altitud");

      Read_Joystick(Current_J);
      Target_Pitch := Pitch_Samples_Type(Current_J(x));
      Display_Altitude(Current_A);
      Display_Pitch(Target_Pitch);

      if Target_Pitch > 30 then
         Target_Pitch := 30;
      elsif Target_Pitch < -30 then
         Target_Pitch := -30;
      end if;

      Current_A := Read_Altitude;
      
      -- Altitud inferior o igual a 2000m 

      if (Current_A <= 2000) then
         Cabeceo_Alabeo_Protegido.Set_Pitch(0);
         if Target_Pitch < 0 then
            -- Ignorar entrada de descenso cuando está por debajo de 2000 m
            Target_Pitch := 0;
         end if;
      elsif (Current_A >= 10000) then
         -- Nivelar la aeronave si la altitud es igual o superior a 10,000 m
         Cabeceo_Alabeo_Protegido.Set_Pitch(0);
         if Target_Pitch > 0 then
            -- Ignorar entrada de ascenso cuando está por encima de 10,000 m
            Target_Pitch := 0;
         end if;
      else
         -- Ajustar el cabeceo según el joystick cuando esté en rango
         Cabeceo_Alabeo_Protegido.Set_Pitch(Target_Pitch);
      end if;

      -- Alertas basadas en altitud
      if (Current_A < 2500) then
         Light_1(On);  -- Alertar cuando desciende por debajo de 2500 m
      elsif (Current_A > 9500) then
         Light_1(On);  -- Alertar cuando sube por encima de 9500 m
      else
         Light_1(Off);  -- Apagar la alerta si está en el rango seguro
      end if;

      Finish_Activity("Control_Cabeceo_Altitud");
      delay until Clock + To_Time_Span(0.2);
   end loop;
end Position_Altitude;



   ----------------------------------------------------------------------
   ------------- procedimientos para probar los dispositivos
   ------------- SE DEBERÁN QUITAR PARA EL PROYECTO
   ----------------------------------------------------------------------
         

begin
   Start_Activity ("Programa Principal");
   --Prueba_Velocidad_Distancia;
   -- Prueba_Altitud_Joystick;
   -- Prueba_Sensores_Piloto;
   Finish_Activity ("Programa Principal");
end fss;
