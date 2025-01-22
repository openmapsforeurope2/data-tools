-- FUNCTION: public.ome2_reduce_precision_3d_trigger_function()

-- DROP FUNCTION IF EXISTS public.ome2_reduce_precision_3d_trigger_function();

CREATE OR REPLACE FUNCTION public.ome2_reduce_precision_3d_trigger_function()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
BEGIN

	-- INSERT / UPDATE
	IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
		-- Mise à jour de la géométrie
		        IF ST_AsText(NEW.geom) LIKE 'MULTI%'THEN
		    NEW.geom := ST_GeomFromText ( ST_AsText ( ST_Force3d ( ST_Multi (ST_ReducePrecision(NEW.geom, 0.1) )), 1 )); 
        ELSE
            NEW.geom := ST_GeomFromText ( ST_AsText ( ST_Force3d ( ST_ReducePrecision(NEW.geom, 0.1) ), 1 )); 
        END IF;

		RETURN NEW;
        
	END IF;

END;
$BODY$;

ALTER FUNCTION public.ome2_reduce_precision_3d_trigger_function()
    OWNER TO postgres;

