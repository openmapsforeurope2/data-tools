CREATE SCHEMA au;
CREATE SCHEMA hy;
CREATE SCHEMA tn;
CREATE SCHEMA ib;
CREATE SCHEMA wk;

-- Pas de gestion de droits sur la GPF (pour une base classique, il faudra lancer les instructions suivantes)
GRANT ALL ON SCHEMA au TO g_ome2_user;
GRANT ALL ON SCHEMA hy TO g_ome2_user;
GRANT ALL ON SCHEMA tn TO g_ome2_user;
GRANT ALL ON SCHEMA ib TO g_ome2_user;
GRANT ALL ON SCHEMA wk TO g_ome2_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON tables TO g_ome2_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA au GRANT ALL ON tables TO g_ome2_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA tn GRANT ALL ON tables TO g_ome2_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA hy GRANT ALL ON tables TO g_ome2_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA ib GRANT ALL ON tables TO g_ome2_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA wk GRANT ALL ON tables TO g_ome2_user;

GRANT ALL ON ALL TABLES IN SCHEMA public TO g_ome2_user;
GRANT ALL ON ALL TABLES IN SCHEMA au TO g_ome2_user;
GRANT ALL ON ALL TABLES IN SCHEMA tn TO g_ome2_user;
GRANT ALL ON ALL TABLES IN SCHEMA hy TO g_ome2_user;
GRANT ALL ON ALL TABLES IN SCHEMA ib TO g_ome2_user;
GRANT ALL ON ALL TABLES IN SCHEMA wk TO g_ome2_user;
