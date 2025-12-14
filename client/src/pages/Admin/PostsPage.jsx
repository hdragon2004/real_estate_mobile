import React, { useEffect, useState } from 'react';
import { Layout, Table, Button, Tag, Space, Modal } from 'antd';
import { EyeOutlined } from '@ant-design/icons';
import Sidebar from '../../components/Sidebar';
import axiosPrivate from '../../api/axiosPrivate';
import MessageProvider from '../../components/MessageProvider';
import { useNavigate } from 'react-router-dom';

const { Content } = Layout;

const PostsPage = () => {
  
  const [pendingPosts, setPendingPosts] = useState([]);
  const [approvedPosts, setApprovedPosts] = useState([]);
  const [loading, setLoading] = useState(true);
  const { showMessage, contextHolder } = MessageProvider();
  const navigate = useNavigate();

  const fetchPosts = async () => {
    try {
      const resPending = await axiosPrivate.get('/api/posts?isApproved=false');
      const resApproved = await axiosPrivate.get('/api/posts?isApproved=true');
      setPendingPosts(resPending.data || []);
      setApprovedPosts(resApproved.data || []);
    } catch (error) {
      console.error('Error fetching posts:', error);
      const errorMessage = error.response?.data?.message || error.response?.data || 'Không thể tải danh sách bài viết';
      showMessage.error(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPosts();
  }, []);

  const handleApprove = async (postId) => {
    try {
      const response = await axiosPrivate.post(`/api/admin/posts/${postId}/approve`);
      const approvedPost = response.data;
      // Remove from pending and add to approved
      setPendingPosts(posts => posts.filter(p => p.id !== postId));
      setApprovedPosts(posts => [approvedPost, ...posts]);
      showMessage.success('Đã duyệt bài viết thành công');
    } catch (error) {
      console.error('Error approving post:', error);
      const errorMessage = error.response?.data?.message || error.response?.data || 'Lỗi duyệt bài viết';
      showMessage.error(errorMessage);
    }
  };

  const handleDelete = async (postId, isPending) => {
    if (window.confirm('Bạn có chắc chắn muốn xóa bài viết này?')) {
      try {
        const response = await axiosPrivate.delete(`/api/admin/posts/${Number(postId)}`);
        if (response.status === 200 || response.status === 204) {
          if (isPending) {
            setPendingPosts(posts => posts.filter(p => p.id !== postId));
          } else {
            setApprovedPosts(posts => posts.filter(p => p.id !== postId));
          }
          showMessage.success('Đã xoá bài viết thành công');
        }
      } catch (error) {
        console.error('Error deleting post:', error);
        const errorMessage = error.response?.data?.message || error.response?.data || 'Không thể xóa bài viết';
        showMessage.error(errorMessage);
      }
    }
  };

  const columns = (isPending) => [
    { title: 'Mã', dataIndex: 'id', key: 'id', width: '8%' },
    { title: 'Tiêu đề', dataIndex: 'title', key: 'title', width: '30%' },
    { title: 'Người đăng', dataIndex: ['user', 'name'], key: 'user', width: '15%' },
    { title: 'Số điện thoại', dataIndex: ['user', 'phone'], key: 'phone', width: '15%' },
    { title: 'Trạng thái', dataIndex: 'isApproved', key: 'isApproved', width: '12%', render: isApproved => (
      <Tag color={isApproved ? 'green' : 'orange'}>{isApproved ? 'Đã duyệt' : 'Chờ duyệt'}</Tag>
    ) },
    {
      title: 'Hành động',
      key: 'action',
      width: '20%',
      render: (_, record) => {
        console.log(`Rendering action column for post ID: ${record.id}`);
        return (
          <Space>
            <Button icon={<EyeOutlined />} onClick={() => navigate(`/chi-tiet/${record.id}`)} />
            {isPending && <Button type="primary" onClick={() => handleApprove(record.id)}>Duyệt</Button>}
            <Button danger onClick={() => handleDelete(record.id, isPending)}>Xoá</Button>
          </Space>
        );
      },
    },
  ];

  return (
    <Layout style={{ minHeight: '100vh' }}>
      {contextHolder}
      <Sidebar selectedKey="/admin/posts" />
      <Layout>
        <Content style={{ margin: '24px 16px 0', background: '#141414' }}>
          <h1 style={{ color: '#fff', fontSize: 24, fontWeight: 700 }}>Quản lý bài viết</h1>
          <h2 style={{ color: '#fff', marginTop: 24 }}>Bài viết chờ duyệt</h2>
          <Table columns={columns(true)} dataSource={pendingPosts} loading={loading} rowKey="id" style={{ marginTop: 12 }} />
          <h2 style={{ color: '#fff', marginTop: 32 }}>Bài viết đã duyệt</h2>
          <Table columns={columns(false)} dataSource={approvedPosts} loading={loading} rowKey="id" style={{ marginTop: 12 }} />
        </Content>
      </Layout>
    </Layout>
  );
};

export default PostsPage; 