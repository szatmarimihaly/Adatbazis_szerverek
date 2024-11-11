CREATE TABLE Konyvek(
    konyv_id SERIAL PRIMARY KEY,
    isbn VARCHAR(14) UNIQUE NOT NULL,
    cim VARCHAR(255) NOT NULL,
    szerzo VARCHAR(255) NOT NULL,
    kiado VARCHAR(255),
    ar NUMERIC(10, 2) NOT NULL,
    keszlet INT DEFAULT 0 CHECK(keszlet >= 0)
);

CREATE INDEX index_konyvek_cim ON Konyvek(cim);

CREATE TABLE Vasarlok(
    vasarlo_id SERIAL PRIMARY KEY,
    nev VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    telefon VARCHAR(20),
    cim VARCHAR(255)
);

CREATE INDEX index_vasarlo_nev ON Vasarlok(nev);

CREATE TABLE Rendelesek(
    rendeles_id SERIAL PRIMARY KEY,
    vasarlo_id INT NOT NULL,
    rendeles_datum TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    statusz VARCHAR(50) DEFAULT 'Feldolgozás alatt',
    FOREIGN KEY (vasarlo_id) REFERENCES Vasarlok(vasarlo_id) ON DELETE CASCADE
);

CREATE INDEX index_rendelesek_datum ON Rendelesek(rendeles_datum);

CREATE TABLE Rendeles_tetelek(
    rendeles_tetel_id SERIAL PRIMARY KEY,
    rendeles_id INT NOT NULL,
    konyv_id INT NOT NULL,
    darabszam INT NOT NULL CHECK (darabszam >= 0),
    tetel_ar NUMERIC(10, 2) NOT NULL,
    FOREIGN KEY (rendeles_id) REFERENCES Rendelesek(rendeles_id) ON DELETE CASCADE,
    FOREIGN KEY (konyv_id) REFERENCES Konyvek(konyv_id)
);

CREATE INDEX index_rendeles_tetelek_rendeles ON Rendeles_tetelek(rendeles_id);
CREATE INDEX index_rendeles_tetelek_konyv ON Rendeles_tetelek(konyv_id);

CREATE TABLE Szamlak(
    szamla_id SERIAL PRIMARY KEY,
    rendeles_id INT NOT NULL,
    szamla_datum TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    osszeg NUMERIC(10, 2) NOT NULL,
    FOREIGN KEY (rendeles_id) REFERENCES Rendelesek(rendeles_id) ON DELETE CASCADE
);

CREATE INDEX index_szamlak_datum ON Szamlak(szamla_datum);

INSERT INTO Konyvek(isbn, cim, szerzo, kiado, ar, keszlet)
VALUES
    ('12345678912345', 'Egri csillagok', 'Gárdonyi Géza', 'Móra Könykiadó', 3999, 10),
    ('23456789123456', 'Az arany ember', 'Jókai Mór', 'Móra Könykiadó', 4300, 7),
    ('34567891234567', 'A kőszívű ember fiai', 'Jókai Mór', 'Holnap Könyvkiadő', 2870, 12);

INSERT INTO Vasarlok(nev, email, telefon, cim)
VALUES
    ('Kiss Máté', 'kissmate@gmail.com', '+36303831042', 'Budapest, Ó utca 1.'),
    ('Kiss Anna', 'kissanna@gmail.com', '+36303834120', 'Baja, Kossuth tér 3.'),
    ('Tóth Balázs', 'tothbalazs@gmail.com', '+36304241010', 'Budapest, Őzike út 3.');

INSERT INTO Rendelesek (vasarlo_id, statusz)
VALUES
    (1, 'Szállítás alatt');

INSERT INTO Rendelesek(vasarlo_id, rendeles_datum, statusz)
VALUES
    (3, '2024-11-11 10:30:00', 'Szállítás alatt'),
    (2, '2024-11-09 14:45:00', 'Feldolgozás alatt'),
    (1, '2024-11-10 09:00:00', 'Teljesítve');

INSERT INTO Rendeles_tetelek(rendeles_id, konyv_id, darabszam, tetel_ar)
VALUES
    (1, 1, 2, 3999),
    (2,2,1,4300),
    (3, 3, 3, 2870);

INSERT INTO Szamlak(rendeles_id, szamla_datum, osszeg)
VALUES
    (1, '2024-11-11 09:30:00', 7998.00),
    (2, '2024-11-11 10:00:00', 4300);

INSERT INTO Szamlak(rendeles_id, osszeg)
VALUES
    (3, 8610);

SELECT *
FROM Konyvek
WHERE cim LIKE '%ember%';

SELECT * 
FROM Rendelesek 
WHERE rendeles_datum > '2024-11-09';

SELECT * 
FROM Vasarlok 
WHERE nev LIKE 'Kiss%';

-- Számla generálása
CREATE OR REPLACE FUNCTION generate_szamla(p_rendeles_id INT)
RETURNS VOID AS $$
DECLARE
    osszeg NUMERIC(10, 2);
BEGIN
    SELECT SUM(tetel_ar * darabszam) INTO osszeg
    FROM Rendeles_tetelek
    WHERE rendeles_id = p_rendeles_id;

    INSERT INTO Szamlak (rendeles_id, osszeg)
    VALUES (p_rendeles_id, osszeg);
END;
$$ LANGUAGE plpgsql;

SELECT generate_szamla(1);
SELECT generate_szamla(2);
SELECT generate_szamla(3);

SELECT * FROM Szamlak;

CREATE OR REPLACE FUNCTION legjobban_fogyokonyvek()
RETURNS TABLE(konyv_id INT, osszes_darabszam INT) AS $$
BEGIN
    RETURN QUERY
    SELECT konyv_id, SUM(darabszam) AS osszes_darabszam
    FROM Rendeles_tetelek
    GROUP BY konyv_id
    ORDER BY osszes_darabszam DESC
    LIMIT 5;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION legaktivabb_vasarlok()
RETURNS TABLE(vasarlo_id INT, rendelesek_szama INT) AS $$
BEGIN
    RETURN QUERY
    SELECT vasarlo_id, COUNT(*) AS rendelesek_szama
    FROM Rendelesek
    GROUP BY vasarlo_id
    ORDER BY rendelesek_szama DESC
    LIMIT 5;
END;
$$ LANGUAGE plpgsql;






