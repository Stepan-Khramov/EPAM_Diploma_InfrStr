output "elb_fqdn" {
    value = aws_elb.diploma_lb.dns_name
}

 output "diploma_inst-01_fqdn" {
     value = aws_instance.diploma_k8s_node-01.public_dns
 }

 output "diploma_inst-02_fqdn" {
     value = aws_instance.diploma_k8s_node-02.public_dns
 }

output "diploma_inst-03_fqdn" {
     value = aws_instance.diploma_k8s_node-03.public_dns
 }

 output "diploma_db_fqdn" {
     value = aws_db_instance.diploma_db.address
 }