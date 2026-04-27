CREATE TABLE CUSTOMER
(
  customer_id INT NOT NULL,
  full_name VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  register_date DATE NOT NULL,
  PRIMARY KEY (customer_id),
  UNIQUE (email)
);

CREATE TABLE ATTRACTION
(
  attraction_id INT NOT NULL,
  attraction_name VARCHAR(100) NOT NULL,
  city VARCHAR(50) NOT NULL,
  category VARCHAR(50) NOT NULL,
  description VARCHAR(255),
  PRIMARY KEY (attraction_id)
);

CREATE TABLE TICKET
(
  ticket_id INT NOT NULL,
  purchase_date DATE NOT NULL,
  visit_date DATE NOT NULL,
  price NUMERIC(10,2) NOT NULL CHECK (price > 0),
  ticket_status VARCHAR(30) NOT NULL,
  customer_id INT NOT NULL,
  attraction_id INT NOT NULL,
  PRIMARY KEY (ticket_id),
  FOREIGN KEY (customer_id) REFERENCES CUSTOMER(customer_id),
  FOREIGN KEY (attraction_id) REFERENCES ATTRACTION(attraction_id)
);

CREATE TABLE REVIEW
(
  review_id INT NOT NULL,
  rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title VARCHAR(100),
  content VARCHAR(1000) NOT NULL,
  review_date DATE NOT NULL,
  is_deleted BOOLEAN NOT NULL,
  deleted_date DATE,
  ticket_id INT NOT NULL,
  PRIMARY KEY (review_id),
  FOREIGN KEY (ticket_id) REFERENCES TICKET(ticket_id)
);

CREATE TABLE REVIEWREACTION
(
  reaction_id INT NOT NULL,
  reaction_type VARCHAR(30) NOT NULL CHECK (reaction_type IN ('like', 'dislike')),
  reaction_date DATE NOT NULL,
  review_id INT NOT NULL,
  customer_id INT NOT NULL,
  PRIMARY KEY (reaction_id),
  FOREIGN KEY (review_id) REFERENCES REVIEW(review_id),
  FOREIGN KEY (customer_id) REFERENCES CUSTOMER(customer_id)
);

CREATE TABLE REVIEWREPORT
(
  report_id INT NOT NULL,
  report_reason VARCHAR(100) NOT NULL,
  report_description VARCHAR(500),
  report_date DATE NOT NULL,
  admin_decision VARCHAR(50),
  decision_date DATE,
  customer_id INT NOT NULL,
  review_id INT NOT NULL,
  PRIMARY KEY (report_id),
  FOREIGN KEY (customer_id) REFERENCES CUSTOMER(customer_id),
  FOREIGN KEY (review_id) REFERENCES REVIEW(review_id)
);