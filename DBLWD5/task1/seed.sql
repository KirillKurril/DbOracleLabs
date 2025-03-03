CREATE SEQUENCE audit_seq
    START WITH 1          
    INCREMENT BY 1        
    NOCACHE;

CREATE TABLE artists (
    artist_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    artist_name VARCHAR2(100) NOT NULL,
    country VARCHAR2(50),
    formed_date DATE
);

CREATE TABLE albums (
    album_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    artist_id NUMBER,
    album_name VARCHAR2(150) NOT NULL,
    release_date DATE,
    total_tracks NUMBER(3),
    CONSTRAINT fk_artist FOREIGN KEY (artist_id) REFERENCES artists(artist_id) ON DELETE CASCADE
);

CREATE TABLE tracks (
    track_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    album_id NUMBER,
    track_name VARCHAR2(200) NOT NULL,
    duration_seconds NUMBER(5),
    CONSTRAINT fk_album FOREIGN KEY (album_id) REFERENCES albums(album_id) ON DELETE CASCADE
);

CREATE TABLE audit_artists (
    audit_id NUMBER PRIMARY KEY,
    operation_type VARCHAR2(10),
    artist_id NUMBER,
    old_artist_name VARCHAR2(100),
    new_artist_name VARCHAR2(100),
    old_country VARCHAR2(50),
    new_country VARCHAR2(50),
    old_formed_date DATE,
    new_formed_date DATE,
    operation_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
    operation_user VARCHAR2(100) DEFAULT USER
);

CREATE TABLE audit_albums (
    audit_id NUMBER PRIMARY KEY,
    operation_type VARCHAR2(10),
    album_id NUMBER,
    old_artist_id NUMBER,
    new_artist_id NUMBER,
    old_album_name VARCHAR2(150),
    new_album_name VARCHAR2(150),
    old_release_date DATE,
    new_release_date DATE,
    old_total_tracks NUMBER(3),
    new_total_tracks NUMBER(3),
    operation_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
    operation_user VARCHAR2(100) DEFAULT USER
);

CREATE TABLE audit_tracks (
    audit_id NUMBER PRIMARY KEY,
    operation_type VARCHAR2(10),
    track_id NUMBER,
    old_album_id NUMBER,
    new_album_id NUMBER,
    old_track_name VARCHAR2(200),
    new_track_name VARCHAR2(200),
    old_duration_seconds NUMBER(5),
    new_duration_seconds NUMBER(5),
    operation_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
    operation_user VARCHAR2(100) DEFAULT USER
);

CREATE TABLE report_timestamps (
    report_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    report_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
);