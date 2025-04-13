FROM python:3.9
WORKDIR /app
COPY . .
RUN pip install flask flask_sqlalchemy psycopg2-binary
CMD ["python", "app.py"]