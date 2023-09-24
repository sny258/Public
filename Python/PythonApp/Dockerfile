FROM python:3.8-slim-buster

WORKDIR /python-app
COPY custommetric.py app.py .
#COPY app.py .
#RUN pip3 install flask
RUN pip3 install flask && pip3 install requests

ENTRYPOINT [ "python" ]
CMD ["app.py" ]
