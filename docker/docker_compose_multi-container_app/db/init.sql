-- Crea il database (se non esiste già)
CREATE DATABASE IF NOT EXISTS mydb;

-- Usa il database appena creato
\c mydb;

-- Creazione della tabella users
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,        -- id univoco per ogni utente
    username VARCHAR(100) NOT NULL, -- nome utente
    email VARCHAR(100) NOT NULL UNIQUE, -- email univoca
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- data di creazione
);

-- Creazione della tabella posts (un esempio di tabella per i post degli utenti)
CREATE TABLE IF NOT EXISTS posts (
    id SERIAL PRIMARY KEY,        -- id univoco per ogni post
    user_id INT NOT NULL,         -- riferimento all'utente che ha creato il post
    title VARCHAR(200) NOT NULL,  -- titolo del post
    content TEXT,                 -- contenuto del post
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- data di creazione
    FOREIGN KEY (user_id) REFERENCES users(id) -- relazione con la tabella users
);

-- Inserimento di utenti di esempio
INSERT INTO users (username, email) 
VALUES 
('admin', 'admin@example.com'),
('guest', 'guest@example.com'),
('john_doe', 'john.doe@example.com');

-- Inserimento di post di esempio
INSERT INTO posts (user_id, title, content)
VALUES
(1, 'First Post', 'This is the first post content.'),
(2, 'Guest Post', 'This is a post from the guest user.'),
(3, 'John\'s First Post', 'John has just created his first post.');

-- Aggiungi un indice per migliorare le performance nelle ricerche sugli utenti
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Aggiungi un indice per migliorare le performance sulle query sui post
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
