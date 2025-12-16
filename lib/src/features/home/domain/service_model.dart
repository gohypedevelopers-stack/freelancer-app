import 'package:flutter/material.dart';

class Service {
  final String title;
  final String description;
  final String price;
  final IconData icon;

  const Service({
    required this.title,
    required this.description,
    required this.price,
    required this.icon,
  });
}

const List<Service> allServices = [
  Service(
    title: "Website Development",
    description: "Custom business websites, landing pages and e-commerce stores.",
    price: "Starting at ₹15,000",
    icon: Icons.code,
  ),
  Service(
    title: "App Development",
    description: "Native and cross-platform mobile applications for iOS and Android.",
    price: "Starting at ₹25,000",
    icon: Icons.phone_android,
  ),
  Service(
    title: "Software Development",
    description: "Custom software solutions, SaaS platforms and enterprise tools.",
    price: "Starting at ₹30,000",
    icon: Icons.computer,
  ),
  Service(
    title: "Lead Generation",
    description: "Targeted leads & outreach campaigns to grow sales funnel.",
    price: "Starting at ₹15,000",
    icon: Icons.adjust,
  ),
  Service(
    title: "Video Services",
    description: "Promo, explainer, ads and product videos.",
    price: "Starting at ₹7,500",
    icon: Icons.videocam,
  ),
  Service(
    title: "SEO Optimization",
    description: "Rank higher on Google with on-page, off-page and technical SEO.",
    price: "Starting at ₹8,000",
    icon: Icons.search,
  ),
  Service(
    title: "Social Media Management",
    description: "Content creation, scheduling and community management.",
    price: "Starting at ₹12,000",
    icon: Icons.share,
  ),
  Service(
    title: "Performance Marketing",
    description: "Paid ad campaigns (PPC) on Google, Facebook, and Instagram.",
    price: "Starting at ₹15,000",
    icon: Icons.show_chart,
  ),
  Service(
    title: "Creative & Design",
    description: "Logo, branding, UI/UX and visual design services.",
    price: "Starting at ₹3,500",
    icon: Icons.palette,
  ),
  Service(
    title: "Writing & Content",
    description: "Blogs, website copy, ad copy and scripts.",
    price: "Starting at ₹2,000",
    icon: Icons.description,
  ),
  Service(
    title: "Customer Support",
    description: "Chat, email or voice support setup and staffing.",
    price: "Starting at ₹8,000",
    icon: Icons.headset_mic,
  ),
  Service(
    title: "Audio Services",
    description: "Voiceover, podcast editing, music & audio production.",
    price: "Starting at ₹2,000",
    icon: Icons.mic,
  ),
];
