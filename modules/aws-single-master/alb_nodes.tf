resource "aws_lb" "k8s-nodes" {
  name               = "${var.cluster_name}-${var.environment}-nodes-a"
  internal           = false
  load_balancer_type = "application"
  subnets             = ["${flatten(aws_subnet.public-subnet.*.id)}"]
  security_groups = ["${aws_security_group.k8s-nodes.id}"]
  enable_deletion_protection = false
  enable_cross_zone_load_balancing = false
  idle_timeout = 400
  tags {
    Name = "${var.cluster_name}-${var.environment}-nodes-alb"
    Environment = "production"
  }
}

resource "aws_lb_listener" "k8s-nodes-http" {
  load_balancer_arn = "${aws_lb.k8s-nodes.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "k8s-nodes-https" {
  load_balancer_arn = "${aws_lb.k8s-nodes.arn}"
  port              = "443"
  protocol          = "HTTPS"
  // https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = "${data.aws_acm_certificate.transactionale-certificate.arn}"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.k8s-nodes.arn}"
  }
}

data "aws_acm_certificate" "transactionale-certificate" {
  domain      = "*.transactionale.com"
  statuses    = ["ISSUED"]
  most_recent = true
}

resource "aws_lb_target_group" "k8s-nodes" {
  name     = "k8s-nodes"
  port     = 31080
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.kube-vpc.id}"
  target_type = "instance"
  health_check {
    path                = "/healthz"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    protocol            = "HTTP"
    port                = "31080"
  }
}

resource "aws_autoscaling_attachment" "k8s-nodes" {
  autoscaling_group_name = "${aws_autoscaling_group.k8s-nodes.id}"
  alb_target_group_arn   = "${aws_lb_target_group.k8s-nodes.arn}"
}

resource "aws_security_group" "k8s-nodes" {
  name        = "${var.cluster_name}-${var.environment}-web"
  description = "k8s ELB Security Group"
  vpc_id      = "${aws_vpc.kube-vpc.id}"

  tags {
    Name = "${var.cluster_name}-k8s-elb-${var.environment}-web"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  //allow everything in egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
