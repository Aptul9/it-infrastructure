# Use an official Python runtime as a parent image
FROM python:3.9-alpine

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container
COPY . /app

# Install Flask
RUN pip install flask

# Make the container's port 5000 available
EXPOSE 5000

# Define environment variable to avoid buffering
ENV PYTHONUNBUFFERED=1

# Run app
CMD ["python", "flask_test_api.py"]
