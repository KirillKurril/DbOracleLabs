CREATE TABLE artists (
    artist_id NUMBER PRIMARY KEY,
    artist_name VARCHAR2(100) NOT NULL,
    country VARCHAR2(50),
    formed_date DATE
);

CREATE TABLE albums (
    album_id NUMBER PRIMARY KEY,
    artist_id NUMBER,
    album_name VARCHAR2(150) NOT NULL,
    release_date DATE,
    total_tracks NUMBER(3),
    CONSTRAINT fk_artist FOREIGN KEY (artist_id) REFERENCES artists(artist_id)
);

CREATE TABLE tracks (
    track_id NUMBER PRIMARY KEY,
    album_id NUMBER,
    track_name VARCHAR2(200) NOT NULL,
    duration_seconds NUMBER(5),
    CONSTRAINT fk_album FOREIGN KEY (album_id) REFERENCES albums(album_id)
);

CREATE TABLE report_timestamps (
    report_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    report_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
);