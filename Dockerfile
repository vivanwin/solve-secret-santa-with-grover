FROM mcr.microsoft.com/quantum/samples:latest

ENV PORT 8080
EXPOSE 8080

WORKDIR /code

COPY ./requirements.txt /code/requirements.txt

RUN pip3 install --no-cache-dir --upgrade -r /code/requirements.txt

COPY ./ /code/

CMD ["uvicorn", "host:app", "--host", "0.0.0.0", "--port", "8080"]