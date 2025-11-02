DROP TABLE IF EXISTS animaux;
CREATE TABLE animaux (
  id INTEGER, 
  famille_id INTEGER, 
  sexe VARCHAR, 
  presence INTEGER, 
  apprivoise INTEGER,
  mort_ne INTEGER, 
  decede INTEGER,
  PRIMARY KEY (id),
  FOREIGN KEY (famille_id) REFERENCES familles (id)
);

DROP TABLE IF EXISTS animaux_types;
CREATE TABLE animaux_types (
  animal_id INTEGER, 
  type_id INTEGER, 
  pourcentage INTEGER,
  PRIMARY KEY (animal_id, type_id),
  FOREIGN KEY (animal_id) REFERENCES animaux (id),
  FOREIGN KEY (type_id) REFERENCES types (id)
);


DROP TABLE IF EXISTS animaux_velages;
CREATE TABLE animaux_velages (
  animal_id INTEGER,
  velage_id INTEGER,
  PRIMARY KEY (animal_id, velage_id),
  FOREIGN KEY (animal_id) REFERENCES animaux (id),
  FOREIGN KEY (velage_id) REFERENCES velages (id)
);

DROP TABLE IF EXISTS complications;
CREATE TABLE complications (
  id INTEGER,
  complication TEXT UNIQUE NOT NULL,
  PRIMARY KEY (id)
);

DROP TABLE IF EXISTS familles;
CREATE TABLE familles (
  id INTEGER,
  nom VARCHAR
);

DROP TABLE IF EXISTS types;
CREATE TABLE types (
  id INTEGER,
  types VARCHAR
);

DROP TABLE IF EXISTS velages;
CREATE TABLE velages (
  id INTEGER,
  mere_id INTEGER,
  pere_id INTEGER,
  date TIMESTAMP NOT NULL,
  FOREIGN KEY (mere_id) REFERENCES animaux (id),
  FOREIGN KEY (pere_id) REFERENCES animaux (id)
);

DROP TABLE IF EXISTS velages_complications;
CREATE TABLE velages_complications (
  velage_id INTEGER,
  complication_id INTEGER,
  PRIMARY KEY (velage_id, complication_id),
